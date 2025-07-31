require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'tvdb-calendar'
  c.service_version = '1.0.0'
  c.use_all() # Let OpenTelemetry automatically configure all available instrumentations
end

# Global tracer instance
TRACER = OpenTelemetry.tracer_provider.tracer('tvdb-calendar')

# Monkey patch to add request_id to all Rails request spans
if defined?(Rails)
  Rails.application.config.after_initialize do
    # Hook into ActionController to add request_id to spans
    ActiveSupport::Notifications.subscribe('start_processing.action_controller') do |name, start, finish, id, payload|
      if OpenTelemetry::Trace.current_span != OpenTelemetry::Trace::Span::INVALID
        request_id = payload[:headers]&.env&.[]('action_dispatch.request_id')
        if request_id
          OpenTelemetry::Trace.current_span.set_attribute('http.request_id', request_id)
        end
      end
    end
  end
end