class Api::V1::TeamsController < Api::V1::ApplicationController
  load_and_authorize_resource :team

  def index
    @teams = @teams.map { |team| Api::V1::TeamPresenter.new(team) }
  end

  def show
    @team = Api::V1::TeamPresenter.new(@team)
    render
  end

  def update
    if @team.update(team_params)
      @team = Api::V1::TeamPresenter.new(@team)
      render action: :show
    else
      render json: @team.errors.as_json, status: :unprocessable_entity
    end
  end

  def destroy
    if !@team.racks.empty? && !ActiveModel::Type::Boolean.new.cast(params[:recurse])
      error = {status: "422", title: "Unprocessable Content", description: "Cannot delete team as they have active racks"}
      render json: {errors: [error]}, status: :unprocessable_entity
    elsif TeamServices::Delete.call(@team)
      render json: {}, status: :ok
    else
      render json: @team.errors.as_json, status: :unprocessable_entity
    end
  end

  private

  def team_params
    permitted_params =
      if current_user.root?
        [:project_id, :cost, :credits, :billing_acct_id, :billing_period_start, :billing_period_end]
      else
        []
      end
    params.require(:team).permit(*permitted_params)
  end
end
