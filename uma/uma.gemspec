require_relative "lib/uma/version"

Gem::Specification.new do |spec|
  spec.name        = "uma"
  spec.version     = Uma::VERSION
  spec.authors     = ["Ben Armston"]
  spec.email       = ["ben.armston@alces-flight.com"]
  spec.homepage    = "https://github.com/alces-flight/concertim-ct-visualisation-app/uma"
  spec.summary     = "User management and authentication engine"
  # spec.description = "TODO: Description of Uma."
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alces-flight/concertim-ct-visualisation-app/uma"
  # spec.metadata["changelog_uri"] = "https://github.com/alces-flight/concertim-ct-visualisation-app/uma/CHANGELOG"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end
end
