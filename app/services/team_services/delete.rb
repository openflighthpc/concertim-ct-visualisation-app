module TeamServices
  class Delete
    def self.call(team)
      config = CloudServiceConfig.first
      if config.nil?
        Rails.logger.info("Unable to delete team: CloudServiceConfig has not been created")
        return false
      end

      team.mark_as_pending_deletion
      DeleteTeamJob.perform_later(team, config)
    end
  end
end
