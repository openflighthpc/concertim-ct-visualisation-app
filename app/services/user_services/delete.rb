module UserServices
  class Delete
    def self.call(user)
      config = CloudServiceConfig.first
      if config.nil?
        Rails.logger.info("Unable to delete user: CloudServiceConfig has not been created")
        return false
      end

      user.mark_as_pending_deletion
      UserDeletionJob.perform_later(user, config)
    end
  end
end
