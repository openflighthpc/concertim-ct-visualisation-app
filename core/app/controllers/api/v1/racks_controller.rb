class Api::V1::RacksController < Api::V1::ApplicationController
  load_and_authorize_resource :rack, :class => Ivy::HwRack

  def index
    @racks = @racks.map {|rack| Api::V1::RackPresenter.new(rack)}
    render
  end

  def show
    @rack = Api::V1::RackPresenter.new(@rack)
    @include_occupation_details = true
    render
  end

  def create
    @rack = Ivy::HwRackServices::Create.call(rack_params.to_h, current_user)

    if @rack.persisted?
      @rack = Api::V1::RackPresenter.new(@rack)
      render action: :show
    else
      render json: @rack.errors.as_json, status: :unprocessable_entity
    end
  end

  def update
    if @rack.update(rack_params)
      @rack = Api::V1::RackPresenter.new(@rack)
      render action: :show
    else
      render json: @rack.errors.as_json, status: :unprocessable_entity
    end
  end

  #
  # DELETE /racks/1
  #
  def destroy
    if !@rack.empty? && !ActiveModel::Type::Boolean.new.cast(params[:recurse])
      render json: {errors: "rack is not empty"}, status: :unprocessable_entity
    elsif @rack.destroy
      render json: {}, status: :ok
    else
      render json: @rack.errors.as_json, status: :unprocessable_entity
    end
  end

  private

  PERMITTED_PARAMS = %w[name description u_height status cost] << {metadata: {}}
  def rack_params
    permitted = PERMITTED_PARAMS.dup.tap do |a|
      a << :user_id if current_user.root? && params[:action] == 'create'
    end
    params.fetch(:rack).permit(*permitted)
  end
end
