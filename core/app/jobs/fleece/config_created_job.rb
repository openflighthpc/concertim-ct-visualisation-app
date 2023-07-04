class Fleece::ConfigCreatedJob < ApplicationJob
  queue_as :default

  def perform(config, **options)
    # The fleece config has just been created, if any users have signed up, we
    # should send their details to the user handler service now.
    Uma::User.where(root: false).each do |user|
      Uma::UserSignupJob.perform_later(user, config)
    end
  end
end
