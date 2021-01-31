
# -*- encoding: utf-8 -*-
require File.expand_path("../lib/voyager/version", __FILE__)

Gem::Specification.new do |s|
  s.name	= 'voyager'
  s.date	= '2021-01-12'
  s.summary	= "Voyager"
  s.version	= Voyager::VERSION
  s.platform    = Gem::Platform::RUBY
  s.description = "Social Media APIs"
  s.authors	= ["Christopher Wu"]
  s.email	= 'cwu@careerarc.com'
  s.homepage	= 'https://github.com/CareerArcGroup/voyager'
  s.license = 'MIT'

  s.add_dependency "oauth", "~> 0"
  s.add_dependency "oauth2", "~> 1.4"
  s.add_dependency "json", "~> 2.2"
  s.add_dependency "multipart-post", "~> 2.1.1"
  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "simplecov", "~> 0"
  s.add_development_dependency 'rubocop', '~> 0.64.0'
  s.add_development_dependency 'pry', '~> 0.12'
  s.add_development_dependency 'pry-byebug', '~> 3.7'

  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
