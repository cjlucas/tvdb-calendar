class SyncChannel < ApplicationCable::Channel
  def subscribed
    user_id = params[:user_id]
    channel_name = "sync_#{user_id}"
    stream_from channel_name
    Rails.logger.info "SyncChannel: User #{user_id} subscribed to channel: #{channel_name}"
    Rails.logger.info "SyncChannel: Current subscriber count: #{ActionCable.server.connections.count}"
  end

  def unsubscribed
    Rails.logger.info "SyncChannel: User unsubscribed from sync updates"
  end
end