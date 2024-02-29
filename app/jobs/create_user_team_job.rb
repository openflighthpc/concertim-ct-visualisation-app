class CreateUserTeamJob < CreateTeamJob
  queue_as :default
  retry_on ::ActiveModel::ValidationError, wait: :polynomially_longer, attempts: 10

  def perform(user, cloud_service_config, **options)
    team = nil

    ActiveRecord::Base.transaction do
      team = Team.new(name: "#{user.name}_team", single_user: true)
      unless team.save
        logger.info("Unable to create team for #{user.name} #{team.errors.full_messages.join("; ")}")
        raise ActiveModel::ValidationError, team
      end

      team_role = TeamRole.new(team: team, user: user, role: "admin")
      unless team_role.save
        logger.info("Unable to create team role for #{user.name} #{team_role.errors.full_messages.join("; ")}")
        logger.info("Rolling back creation of team #{team.name}")
        raise ActiveModel::ValidationError, team_role
      end
    end

    CreateTeamJob.perform_later(team, cloud_service_config)
  end
end
