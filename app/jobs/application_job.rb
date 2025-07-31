class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  around_perform do |job, block|
    # Extract trace context from job arguments if present
    trace_context = job.arguments.find { |arg| arg.is_a?(Hash) && arg.key?('otel_trace_context') }
    
    if trace_context && trace_context['otel_trace_context']
      # Restore the trace context
      OpenTelemetry::Context.with_current(
        OpenTelemetry.propagation.extract(trace_context['otel_trace_context'])
      ) do
        block.call
      end
    else
      block.call
    end
  end

  # Helper method to add trace context to job arguments
  def self.perform_later_with_trace_context(*args)
    # Extract current trace context
    carrier = {}
    OpenTelemetry.propagation.inject(carrier)
    
    # Add trace context to arguments
    args << { 'otel_trace_context' => carrier } unless args.any? { |arg| arg.is_a?(Hash) && arg.key?('otel_trace_context') }
    
    perform_later(*args)
  end
end
