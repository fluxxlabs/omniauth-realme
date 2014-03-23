require File.expand_path('../lib/omniauth-realme/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "omniauth-realme"
  gem.version       = OmniAuth::RealMe::VERSION
  gem.summary       = %q{New Zealand Government RealMe strategy for OmniAuth.}
  gem.description   = %q{New Zealand Government RealMe strategy for OmniAuth developed by Fluxx Labs, based on work by Boost New Media for the National Library of New Zealand.}

  gem.authors       = ["Colin Bean"]
  gem.email         = ["colin@fluxxlabs.com"]
  gem.homepage      = "https://github.com/fluxxlabs/omniauth-realme"

  gem.add_runtime_dependency 'omniauth', '~> 1.0'
  gem.add_runtime_dependency 'uuid', '~> 2.3'
  gem.add_runtime_dependency 'savon'
  gem.add_runtime_dependency 'nokogiri'
  

  gem.files         = ['README.md'] + Dir['lib/**/*.rb']
  gem.test_files    = Dir['spec/**/*.rb']
  gem.require_paths = ["lib"]
end
