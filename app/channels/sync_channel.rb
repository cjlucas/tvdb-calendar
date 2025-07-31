class SyncChannel < ApplicationCable::Channel
  def subscribed
    user_pin = params[:user_pin]
    channel_name = "sync_#{user_pin}"
    
    TRACER.in_span('sync_channel.subscribed', attributes: {
      'user.pin' => user_pin,
      'channel.name' => channel_name
    }) do |span|
      stream_from channel_name
      span.set_attribute('actioncable.connections_count', ActionCable.server.connections.count)
    end
  end

  def unsubscribed
    TRACER.in_span('sync_channel.unsubscribed') do |span|
      span.set_attribute('actioncable.event', 'user_unsubscribed')
    end
  end
end
