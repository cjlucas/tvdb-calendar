module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # No authentication needed for this application
    # identified_by :current_user

    def connect
      TRACER.in_span('actioncable.connection.connect') do |span|
        span.set_attribute('actioncable.event', 'connection_established')
      end
    end

    def disconnect
      TRACER.in_span('actioncable.connection.disconnect') do |span|
        span.set_attribute('actioncable.event', 'connection_disconnected')
      end
    end
  end
end
