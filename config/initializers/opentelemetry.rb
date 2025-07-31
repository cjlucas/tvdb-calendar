require 'opentelemetry/sdk'
require 'opentelemetry/instrumentation/all'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'tvdb-calendar'
  c.service_version = '1.0.0'
  c.use_all() # Let OpenTelemetry automatically configure all available instrumentations
end

# Global tracer instance
TRACER = OpenTelemetry.tracer_provider.tracer('tvdb-calendar')