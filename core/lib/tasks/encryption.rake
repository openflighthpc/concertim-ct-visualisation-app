require 'open3'

namespace :encryption do
  desc 'Add to credentials'
  task generate: :environment do |task|
    if Rails.application.credentials[:active_record_encryption]
      puts "Encryption already in place"
    else
      encryption = `bin/rails db:encryption:init`
      start_pattern = /active_record_encryption/
      match = encryption.match(start_pattern)
      if match
        encryption = encryption[match.begin(0)..-1]
      else
        return "unable to obtain encryption keys"
      end

      `EDITOR='echo "#{encryption}" >> ' rails credentials:edit`
    end
  end
end
