class TeamRolesController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :team_role, except: [:create, :new]

  def index
    @team_roles = resource_table_collection(@team_roles)
    @team = Team.find(params[:team_id])
  end

  def new
    @team = Team.find(params[:team_id])
    @team_role = TeamRole.new(team_id: @team.id)
    authorize! :create, @team_role
    set_possible_users
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @team_role = TeamRole.new(PERMITTED_PARAMS)
    authorize! :create, @team_role

    # TODO
  end

  private

  PERMITTED_PARAMS = %w[user_id team_id role]
  def team_params
    params.fetch(:team).permit(*PERMITTED_PARAMS)
  end

  def set_possible_users
    existing_users = @team.users
    admins = User.where(root: true)
    @possible_users = User.where.not(id: existing_users + admins)
  end
end
