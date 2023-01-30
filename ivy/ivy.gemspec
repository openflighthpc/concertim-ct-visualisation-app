require_relative "lib/ivy/version"

Gem::Specification.new do |spec|
  spec.name        = "ivy"
  spec.version     = Ivy::VERSION
  spec.authors     = ["Ben Armston"]
  spec.email       = ["ben.armston@alces-flight.com"]
  spec.homepage    = "https://github.com/alces-flight/concertim-ct-visualisation-app/ivy"
  spec.summary     = "Hardware and configuration inventory engine"
  # spec.description = "TODO: Description of Ivy."
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alces-flight/concertim-ct-visualisation-app/ivy"
  # spec.metadata["changelog_uri"] = "https://github.com/alces-flight/concertim-ct-visualisation-app/ivy/CHANGELOG"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.4"
  spec.add_dependency "pg", "~> 1.1"
end
