require 'rails_helper'

RSpec.describe Whatsapp::TemplateCategoryUpdateService do
  let(:waba_id) { '123456789' }
  let(:templates) do
    [
      { 'id' => '111', 'name' => 'promo', 'language' => 'fr', 'category' => 'UTILITY', 'status' => 'APPROVED' },
      { 'id' => '222', 'name' => 'promo', 'language' => 'en_US', 'category' => 'UTILITY', 'status' => 'APPROVED' },
      { 'id' => '333', 'name' => 'receipt', 'language' => 'fr', 'category' => 'UTILITY', 'status' => 'APPROVED' }
    ]
  end
  let!(:channel) { cloud_channel }
  let(:change) do
    { message_template_id: 111, message_template_name: 'promo', message_template_language: 'fr',
      previous_category: 'UTILITY', new_category: 'MARKETING' }
  end

  def cloud_channel(business_account_id: waba_id)
    create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false).tap do |c|
      c.update_columns(message_templates: templates,
                       provider_config: c.provider_config.merge('business_account_id' => business_account_id))
    end
  end

  def categories(whatsapp_channel)
    whatsapp_channel.reload.message_templates.to_h { |t| [t['id'], t['category']] }
  end

  it 'writes the new category on the matching template only and queues a sync' do
    expect { described_class.new(waba_id: waba_id, value: change).perform }
      .to have_enqueued_job(Channels::Whatsapp::TemplatesSyncJob).with(channel)

    expect(categories(channel)).to eq('111' => 'MARKETING', '222' => 'UTILITY', '333' => 'UTILITY')
  end

  it 'updates every Cloud inbox on the WABA and leaves other WABAs alone' do
    sibling = cloud_channel
    other_waba = cloud_channel(business_account_id: '999')

    described_class.new(waba_id: waba_id, value: change).perform

    expect(categories(sibling)['111']).to eq('MARKETING')
    expect(categories(other_waba)['111']).to eq('UTILITY')
    expect(Channels::Whatsapp::TemplatesSyncJob).not_to have_been_enqueued.with(other_waba)
  end

  it 'falls back to name and language when the stored template has no id' do
    channel.update_columns(message_templates: templates.map { |t| t.except('id') })

    described_class.new(waba_id: waba_id, value: change).perform

    expect(channel.reload.message_templates.map { |t| t['category'] }).to eq(%w[MARKETING UTILITY UTILITY])
  end

  it 'only queues a sync for an advance notice without previous_category' do
    notice = change.except(:previous_category)

    expect { described_class.new(waba_id: waba_id, value: notice).perform }
      .to have_enqueued_job(Channels::Whatsapp::TemplatesSyncJob).with(channel)
    expect(categories(channel)['111']).to eq('UTILITY')
  end

  it 'does nothing without a WABA id' do
    expect { described_class.new(waba_id: nil, value: change).perform }
      .not_to have_enqueued_job(Channels::Whatsapp::TemplatesSyncJob)
    expect(categories(channel)['111']).to eq('UTILITY')
  end

  it 'copes with a channel whose templates were reset to an empty hash' do
    channel.update_columns(message_templates: {})

    expect { described_class.new(waba_id: waba_id, value: change).perform }.not_to raise_error
  end
end
