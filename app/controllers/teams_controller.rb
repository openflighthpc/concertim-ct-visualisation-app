class TeamsController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :team

  def index
    @teams = resource_table_collection(@teams)
    render
  end

  def edit
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

  # A placeholder action for developing the resource table used on the
  # teams/index page.  This should be removed once we have real actions to go
  # in the actions dropdown.
  def placeholder
    team = Team.find(params[:id])
    flash[:info] = "placeholder action: found user: #{team.name}"
    redirect_back_or_to root_path
  end

  private

  PERMITTED_PARAMS = %w[name cloud_user_id project_id billing_acct_id]
  def team_params
    params.fetch(:team).permit(*PERMITTED_PARAMS)
  end
end
