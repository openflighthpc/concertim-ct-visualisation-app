require 'faraday'

class CreateTeamThenRoleJob < CreateTeamJob
  def perform(team, team_role, cloud_service_config, **options)
    runner = Runner.new(
      team: team,
      team_role: team_role,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Runner < CreateTeamJob::Runner
    def initialize(team_role:, **kwargs)
      @team_role = team_role
      super(**kwargs)
    end

    def call
      super
      CreateTeamRoleJob.perform_later(@team_role, @cloud_service_config)
    end
  end
end
