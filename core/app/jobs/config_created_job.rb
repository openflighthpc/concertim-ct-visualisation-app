class ConfigCreatedJob < ApplicationJob
  queue_as :default

  def perform(config, **options)
    # The config has just been created, if any users have signed up, we
    # should send their details to the user handler service now.
    User.where(root: false).each do |user|
      UserSignupJob.perform_later(user, config)
    end
  end
end
