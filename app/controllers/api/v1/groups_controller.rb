class Api::V1::GroupsController < Api::V1::ApplicationController

  def index
    render json: []
  end

  # There are no groups to show
  def show
    render json: {error: "not found"}, status: :not_found
  end
end
