class TeamRolesController < ApplicationController
  include ControllerConcerns::ResourceTable
  before_action :set_team

  def index
    @team_roles = @team.team_roles.accessible_by(current_ability, :read)
    @team_roles = resource_table_collection(@team_roles)
  end

  def new
    @team_role = TeamRole.new(team_id: @team.id)
    authorize! :create, @team_role
    set_possible_users
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @team_role = @team.team_roles.new(team_role_params)
    authorize! :create, @team_role

    unless @team_role.user&.cloud_user_id
      flash.now[:alert] = "Unable to add user to team: user does not yet have a cloud ID. " \
                      "This will be added automatically shortly."
      set_possible_users
      render action: :new
      return
    end

    unless @team_role.team&.project_id
      flash.now[:alert] = "Unable to add user to team: project does not yet have a project id. " \
                      "This will be added automatically shortly."
      set_possible_users
      render action: :new
      return
    end

    unless @team_role.valid?
      flash.now[:alert] = "Unable to add user to team."
      set_possible_users
      render action: :new
      return
    end

    result = CreateTeamRoleJob.perform_now(@team_role, @cloud_service_config)

    if result.success?
      flash[:success] = "User added to team"
      redirect_to team_team_roles_path(@team)
    else
      flash[:alert] = result.error_message
      set_possible_users
      render action: :new
    end
  end

  private

  PERMITTED_PARAMS = %w[user_id role]
  def team_role_params
    params.fetch(:team_role).permit(*PERMITTED_PARAMS)
  end

  def set_team
    @team = Team.find(params[:team_id])
  end

  def set_possible_users
    existing_users = @team.users
    admins = User.where(root: true)
    @possible_users = User.where.not(id: existing_users + admins)
  end
end
