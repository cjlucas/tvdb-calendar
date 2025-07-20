module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # No authentication needed for this application
    # identified_by :current_user
    
    def connect
      Rails.logger.info "ActionCable: Connection established"
    end
    
    def disconnect
      Rails.logger.info "ActionCable: Connection disconnected"
    end
  end
end