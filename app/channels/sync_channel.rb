class SyncChannel < ApplicationCable::Channel
  def subscribed
    user_pin = params[:user_pin]
    channel_name = "sync_#{user_pin}"
    stream_from channel_name
    Rails.logger.info "SyncChannel: User subscribed to channel: #{channel_name}"
    Rails.logger.info "SyncChannel: Current subscriber count: #{ActionCable.server.connections.count}"
  end

  def unsubscribed
    Rails.logger.info "SyncChannel: User unsubscribed from sync updates"
  end
end