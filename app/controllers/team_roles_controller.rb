class TeamRolesController < ApplicationController
  include ControllerConcerns::ResourceTable
  before_action :set_team, except: [:edit, :update, :destroy]
  load_and_authorize_resource :team_role, only: [:edit, :update, :destroy]

  def index
    authorize! :manage, @team.team_roles.new
    @team_roles = @team.team_roles.accessible_by(current_ability, :read)
    @team_roles = resource_table_collection(@team_roles)
  end

  def new
    @team_role = TeamRole.new(team_id: @team.id)
    authorize! :create, @team_role
  end

  def create
    @team_role = @team.team_roles.new(team_role_params)
    authorize! :create, @team_role

    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash.now.alert = "Unable to create team role: cloud environment config not set."
      render action: :new
      return
    end

    unless @team_role.user&.cloud_user_id
      flash.now[:alert] = "Unable to add user to team: user does not yet have a cloud ID. " \
                      "This will be added automatically shortly."
      render action: :new
      return
    end

    unless @team_role.team&.project_id
      flash.now[:alert] = "Unable to add user to team: team does not yet have a project id. " \
                      "This will be added automatically shortly."
      render action: :new
      return
    end

    unless @team_role.valid?
      flash.now[:alert] = "Unable to add user to team."
      render action: :new
      return
    end

    result = CreateTeamRoleJob.perform_now(@team_role, @cloud_service_config)

    if result.success?
      flash[:success] = "User added to team"
      redirect_to team_team_roles_path(@team)
    else
      flash.now[:alert] = result.error_message
      render action: :new
    end
  end

  def destroy
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash.now.alert = "Unable to remove team role: cloud environment config not set."
      redirect_to edit_team_role_path(@team_role)
      return
    end

    @team = @team_role.team
    result = DeleteTeamRoleJob.perform_now(@team_role, @cloud_service_config)

    if result.success?
      flash[:success] = "User removed from team"
      redirect_to @team_role.user == current_user ? teams_path : team_team_roles_path(@team)
    else
      flash[:alert] = result.error_message
      redirect_to team_team_roles_path(@team)
    end
  end

  def update
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config.nil?
      flash.now[:alert] = "Unable to update team role: cloud environment config not set."
      render action: :edit
      return
    end

    unless team_role_params[:role] != @team_role.role
      flash.now[:warning] = "Role not updated - you have not changed any values"
      render action: :edit
      return
    end

    result = UpdateTeamRoleJob.perform_now(@team_role, team_role_params[:role], @cloud_service_config)

    if result.success?
      flash[:info] = "Successfully updated team role"
      redirect_to @team_role.user == current_user ? teams_path : team_team_roles_path(@team_role.team)
    else
      flash[:alert] = "Unable to update team role"
      render action: :edit
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
end
