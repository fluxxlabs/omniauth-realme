require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'omniauth-realme'

RSpec.configure do |config|
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.extend  OmniAuth::Test::StrategyMacros, :type => :strategy
end
