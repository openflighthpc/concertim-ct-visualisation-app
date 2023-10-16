class Api::V1::ApplicationController < Api::ApplicationController

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found
    respond_to do |format|
      format.json do
        render json: { errors: {record: ["Not found"]} }, status: 404
      end
    end
  end
end
