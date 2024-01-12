class TeamsController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :team, except: :create

  def index
    @teams = resource_table_collection(@teams)
    render
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
      # CreateTeamJob.perform_later(@team, @cloud_service_config)
      flash[:success] = "Team created. Project id and billing account id will be added automatically."
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
      redirect_to teams_path
    else
      flash[:alert] = "Unable to schedule team for deletion"
      redirect_to teams_path
    end
  end

  # A placeholder action for developing the resource table used on the
  # teams/index page.  This should be removed once we have real actions to go
  # in the actions dropdown.
  def placeholder
    team = Team.find(params[:id])
    flash[:info] = "placeholder action: found user: #{team.name}"
    redirect_back_or_to root_path
  end

  private

  PERMITTED_PARAMS = %w[name project_id billing_acct_id]
  def team_params
    params.fetch(:team).permit(*PERMITTED_PARAMS)
  end
end
