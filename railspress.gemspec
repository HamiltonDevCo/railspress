$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "railspress/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "railspress"
  spec.version     = Railspress::VERSION
  spec.authors     = ["True Soft"]
  spec.email       = ["truesoft@ymail.com"]
  spec.homepage    = "https://truesoft.ro/railspress"
  spec.summary     = "Shows WordPress posts in a Ruby on Rails application."
  spec.description = "Integrates WordPress functions in a Ruby on Rails application."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://truesoft.ro"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.metadata["bug_tracker_uri"] = "https://github.com/TrueSoft/railspress/issues"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails" #, "~> 5.2.3"

  spec.add_dependency 'addressable' #, '~> 2.7'

  spec.add_dependency 'sass-rails' #, '~> 5.0'
  spec.add_dependency 'php-serialization' #, '~> 1.0.0'
  spec.add_dependency 'shortcode' #, '~> 2.0.0'
  spec.add_dependency 'will_paginate' #, '~> 3.1.0'

  spec.add_development_dependency "mysql2"
end
