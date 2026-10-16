require "clerk"

Clerk.configure do |config|
  # Optional: Override environment variables
  config.publishable_key = ENV["CLERK_PUBLISHABLE_KEY"]
  config.secret_key = ENV["CLERK_SECRET_KEY"]

  # Enable debug logging
  config.debug = true
  config.logger = Logger.new($stdout)

  # Exclude routes from authentication middleware
  config.excluded_routes = [ "/health", "/public/*" ]

  # Custom cache store (defaults to Rails.cache or ActiveSupport::Cache::MemoryStore)
  config.cache_store = Rails.cache
end
