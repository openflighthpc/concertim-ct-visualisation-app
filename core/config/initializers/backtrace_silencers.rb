# Remove all silencers just to remove one particular silencer.
Rails.backtrace_cleaner.remove_silencers!

# Add back the removed silencers we want.
Rails.backtrace_cleaner.send(:add_gem_silencer)
Rails.backtrace_cleaner.send(:add_stdlib_silencer)

# Add a replacement silencer for the one we wanted to remove.
Rails.backtrace_cleaner.add_silencer { |line| line !~ /\A(?:\.\/)?(?:app|config|lib|test|spec|engine |\(\w*\))/}
