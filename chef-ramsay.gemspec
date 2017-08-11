lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef-ramsay/version'

Gem::Specification.new do |gem|
  gem.name          = 'chef-ramsay'
  gem.version       = Ramsay::VERSION
  gem.license       = 'Apache-2.0'
  gem.authors       = ['Ryan Frantz']
  gem.email         = ['ryanleefrantz@gmail.com']
  gem.description   = 'A tool to generate unit/integration tests for Chef cookbooks and policy files.'
  gem.summary       = gem.description

  gem.required_ruby_version = '>= 2.3'

  gem.files         = Dir['{bin,lib,spec,support,test}/**/*', 'README*', 'LICENSE*', 'CONTRIBUTING*', 'CHANGELOG*']
  gem.test_files    = gem.files.grep(%r{^(test|spec)/})
  gem.require_paths = ['lib']
  gem.executables   << 'ramsay'

  gem.add_dependency 'chef', '~> 12.19'
  gem.add_dependency 'chef-dk', '~> 1.4'
  gem.add_dependency 'rubocop', '~> 0.47'

end
