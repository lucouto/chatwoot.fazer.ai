# Meta can recategorise an approved template (UTILITY → MARKETING and back) and announces it with a
# WABA-level `template_category_update` webhook:
# https://developers.facebook.com/docs/whatsapp/business-management-api/webhooks/components
#
# Sending routes on the category stored with the channel's templates
# (Whatsapp::Providers::WhatsappCloudService#marketing_template?): MARKETING goes to
# /marketing_messages, everything else to /messages. A stale category costs a refused send and a
# retry at best, and a failed message once `disable_marketing_messages_on_cloud_api` is on. So the
# new category is written at once on every Cloud inbox of that WABA (they each keep their own copy
# of the WABA's templates), and a sync is queued to reconcile against what Meta reports.
#
# Meta also announces a change ahead of time. Only the change itself carries `previous_category`,
# so only that one is written here; the sync is queued for both and stores whatever Meta reports.
class Whatsapp::TemplateCategoryUpdateService
  def initialize(waba_id:, value:)
    @waba_id = waba_id.to_s
    @value = (value || {}).to_h.with_indifferent_access
  end

  def perform
    channels.find_each do |channel|
      apply_new_category(channel) if category_changed?
      Channels::Whatsapp::TemplatesSyncJob.perform_later(channel)
    end
  end

  private

  def channels
    return Channel::Whatsapp.none if @waba_id.blank?

    Channel::Whatsapp.where(provider: 'whatsapp_cloud').where("provider_config->>'business_account_id' = ?", @waba_id)
  end

  def category_changed?
    @value[:previous_category].present? && new_category.present?
  end

  def new_category
    @value[:new_category]
  end

  def apply_new_category(channel)
    changed = false
    templates = Array(channel.message_templates).map do |template|
      next template unless same_template?(template) && template['category'] != new_category

      changed = true
      template.merge('category' => new_category)
    end
    return unless changed

    # rubocop:disable Rails/SkipsModelValidations
    channel.update_columns(message_templates: templates)
    # rubocop:enable Rails/SkipsModelValidations
    channel.account.update_cache_key('inbox')
  end

  def same_template?(template)
    return false unless template.is_a?(Hash)
    return template['id'].to_s == @value[:message_template_id].to_s if template['id'].present? && @value[:message_template_id].present?

    template['name'] == @value[:message_template_name] && template['language'] == @value[:message_template_language]
  end
end
