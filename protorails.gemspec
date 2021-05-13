$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "protorails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "protorails"
  spec.version     = Protorails::VERSION
  spec.authors     = ["Kazato Sugimoto"]
  spec.email       = ["yo@zato.tokyo"]
  spec.homepage    = "https://github.com/uiur/protorails"
  spec.summary     = "Summary of Protorails."
  spec.description = "Description of Protorails."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.3", ">= 6.0.3.6"
  spec.add_dependency "twirp"
  spec.add_dependency "grpc-tools"
end
