# Structured Request Logging Middleware
class StructuredRequestLogging
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    request_id = request.request_id

    # Add request_id to the logging context
    Rails.logger.tagged(request_id: request_id) do
      start_time = Time.current

      # Log request start
      Rails.logger.info event: "request_started",
        request_id: request_id,
        method: request.method,
        path: request.path,
        remote_ip: request.remote_ip,
        user_agent: request.user_agent&.truncate(100)

      status, headers, response = @app.call(env)

      duration_ms = ((Time.current - start_time) * 1000).round(2)

      # Log request completion
      Rails.logger.info event: "request_completed",
        request_id: request_id,
        method: request.method,
        path: request.path,
        status: status,
        duration_ms: duration_ms,
        remote_ip: request.remote_ip,
        user_agent: request.user_agent&.truncate(100)

      [ status, headers, response ]
    end
  rescue => e
    # Log request error
    Rails.logger.error event: "request_error",
      request_id: request_id,
      method: request.method,
      path: request.path,
      error: e.message,
      error_class: e.class.name

    raise e
  end
end

# Add the middleware to Rails
Rails.application.config.middleware.use StructuredRequestLogging if Rails.env.development?