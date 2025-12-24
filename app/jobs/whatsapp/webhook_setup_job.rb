class Whatsapp::WebhookSetupJob < ApplicationJob
  queue_as :low

  def perform(channel_id, waba_id, access_token)
    channel = Channel::Whatsapp.find(channel_id)
    Whatsapp::WebhookSetupService.new(channel, waba_id, access_token).perform
    Rails.logger.info("[WHATSAPP] Webhook setup completed for channel #{channel.phone_number}")
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Webhook setup job failed: #{e.message}")
    channel = Channel::Whatsapp.find(channel_id)
    channel.prompt_reauthorization!
    raise
  end
end

