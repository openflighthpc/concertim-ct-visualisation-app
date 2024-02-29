require 'faraday'

class CreateUserTeamJob < CreateTeamJob

  def perform(user, cloud_service_config, **options)
    records_created = false
    team = nil

    ActiveRecord::Base.transaction do
      team = Team.new(name: "#{user.name}_team")
      unless team.save
        logger.info("Unable to create team for #{user.name} #{team.errors.full_messages.join("; ")}")
        return
      end

      team_role = TeamRole.new(team: team, user: user, role: "admin")
      if team_role.save
        records_created = true
      else
        logger.info("Unable to create team role for #{user.name} #{team_role.errors.full_messages.join("; ")}")
        raise ActiveRecord::Rollback, "Team role creation failed, rolling back creation of user team"
      end
    end

    if records_created
      super(team, cloud_service_config, **options)
    else
      raise
    end
  end
end
