Devise.setup do |config|
  require 'devise/orm/active_record'
  config.use_salt_as_remember_token = false
  config.authentication_keys = [:username]
  config.timeout_in = 120.minutes
end
