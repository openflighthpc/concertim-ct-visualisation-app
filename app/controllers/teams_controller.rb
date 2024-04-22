class TeamsController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :team, except: :create

  def index
    @teams = resource_table_collection(@teams)
  end

  def quotas
    @cloud_service_config = CloudServiceConfig.first
    authorize! :read, @team

    if @cloud_service_config.nil?
      flash[:alert] = "Unable to view team quotas: cloud environment config not set."
      redirect_to teams_path_path
      return
    end

    if @team.project_id.nil?
      flash[:alert] = "Unable to view team quotas: team does not have a cloud project."
      redirect_to teams_path_path
      return
    end

    result = GetTeamQuotasJob.perform_now(@cloud_service_config, @team)
    if result.success?
      @quotas = {totals: TeamServices::QuotaStats.call(@team, result.quotas)}
    else
      flash[:alert] = result.error_message
      redirect_to teams_path
    end
  end

  def create
    @cloud_service_config = CloudServiceConfig.first
    @team = Team.new(name: team_params[:name])
    authorize! :create, @team

    if @cloud_service_config.nil?
      flash[:alert] = "Unable to create new team: cloud environment config not set."
      redirect_to new_team_path
      return
    end

    if @team.save
      CreateTeamJob.perform_later(@team, @cloud_service_config)
      flash[:success] = "Team created. Project ID and billing account ID should be added automatically."
      redirect_to teams_path
    else
      flash.now[:alert] = "Unable to create team"
      render action: :new
    end
  end

  def update
    if @team.update(team_params)
      flash[:info] = "Successfully updated team"
      redirect_to teams_path
    else
      flash[:alert] = "Unable to update team"
      render action: :edit
    end
  end

  def destroy
    if TeamServices::Delete.call(@team)
      flash[:info] = "Scheduled team for deletion"
    else
      flash[:alert] = "Unable to schedule team for deletion"
    end
    redirect_to teams_path
  end

  private

  PERMITTED_PARAMS = %w[name project_id billing_acct_id]
  def team_params
    params.fetch(:team).permit(*PERMITTED_PARAMS)
  end
end
