# -*- encoding: utf-8 -*-
require File.expand_path('../lib/force/version', __FILE__)

Gem::Specification.new do |s|
  s.name          = "force"
  s.version       = Force::VERSION
  s.authors       = ["Eric J. Holmes", "Mattt Thompson"]
  s.email         = ["eric@ejholmes.net", "mattt@heroku.com"]
  s.description   = "A lightweight ruby client for the Salesforce REST api."
  s.summary       = "A lightweight ruby client for the Salesforce REST api."
  s.homepage      = "https://github.com/heroku/force"

  s.files         = Dir["./**/*"].reject { |file| file =~ /\.\/(bin|example|log|pkg|script|spec|test|vendor)/ }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'faraday', '~> 0.8.4'
  s.add_dependency 'faraday_middleware', '>= 0.8.8'
  s.add_dependency 'json', ['>= 1.7.5', '< 1.9.0']
  s.add_dependency 'hashie', ['>= 1.2.0', '< 2.1']

  s.add_development_dependency 'rspec', '~> 2.14.0'
  s.add_development_dependency 'webmock', '~> 1.13.0'
  s.add_development_dependency 'simplecov', '~> 0.7.1'
  s.add_development_dependency 'faye' unless RUBY_PLATFORM == 'java'
end
