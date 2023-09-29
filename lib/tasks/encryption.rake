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

        Open3.popen2e({"EDITOR" => "ed"}, "rails credentials:edit") do |stdin, stdout, wait_thr|
          begin
            Timeout.timeout(5) do
              # The following ed script will work as long as encryption doesn't
              # contain a line that itself is just a `.` character.  That really
              # shouldn't happen, but we run this in a timeout anyway.
              stdin.write("$\na\n#{encryption}\n.\nw\nq\n")
              exit_status = wait_thr.value
              if exit_status.success?
                puts "Encryption added"
              else
                puts "Adding encryption failed"
                puts stdout.read
              end
            end
          rescue Timeout::Error
            puts "Adding encryption failed: timeout"
            Process.kill("KILL", wait_thr.pid)
          end
        end
      else
        puts "unable to obtain encryption keys"
      end
    end
  end
end
