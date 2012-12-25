require 'redis'
require 'redis/objects'
if url = ENV["REDISTOGO_URL"]
  uri = URI.parse(url)
  Rails.logger.info("Configured Redis with url #{url}")
  $redis = REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  Redis.current = REDIS
elsif Rails.env.development? or Rails.env.test?
# if you are also using a list or any other complex object, please make sure to "require 'redis/list'" respectively
  Redis.current = Redis.new(:host => '127.0.0.1', :port => 6379)
else
  Rails.logger.error "Failed to initialize Redis as REDISTOGO_URL is missing!"
end