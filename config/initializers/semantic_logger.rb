# Semantic Logger Configuration
if Rails.env.development?
  # Configure Semantic Logger to output JSON format
  SemanticLogger.default_level = :info
  SemanticLogger.application = "tvdb-calendar"
  
  # Add JSON formatter to stdout
  SemanticLogger.add_appender(io: $stdout, formatter: :json)
end