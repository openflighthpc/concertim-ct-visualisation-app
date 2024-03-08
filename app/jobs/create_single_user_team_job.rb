class CreateSingleUserTeamJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Batches
  queue_as :default

  def perform(batch, params)
    @user = batch.properties[:user]
    @cloud_service_config = batch.properties[:cloud_service_config]
    create_team_and_role
    if batch.properties[:stage].nil?
      batch.enqueue(stage: 1) do
        CreateTeamJob.perform_later(@team, @cloud_service_config)
      end
    elsif batch.properties[:stage] == 1
      batch.enqueue(stage: 2) do
        CreateTeamRoleJob.perform_later(@team_role, @cloud_service_config)
      end
    end
  end

  def create_team_and_role
    @team = nil
    @team_role = nil

    ActiveRecord::Base.transaction do
      @team = Team.new(name: "#{@user.login}_team", single_user: true)
      unless @team.save
        logger.info("Unable to create team for #{@user.login} #{@team.errors.details}")
        raise ActiveModel::ValidationError, @team
      end

      @team_role = TeamRole.new(team: @team, user: @user, role: "admin")
      unless @team_role.save
        logger.info("Unable to create team role for #{@user.login} #{@team_role.errors.details}")
        logger.info("Rolling back creation of team #{@team.name}")
        raise ActiveModel::ValidationError, @team_role
      end
    end
  end
end
