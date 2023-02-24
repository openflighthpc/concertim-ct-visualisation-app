class Api::V1::RacksController < Api::V1::ApplicationController
  # load_and_authorize_resource :rack, :class => Ivy::HwRack

  def index
    # XXX load_and_authorize_resource instead.
    @racks = Ivy::HwRack.all
    render
  end

  def show
    # XXX load_and_authorize_resource instead.
    @rack = Api::V1::RackPresenter.new(Ivy::HwRack.find(params[:id]))
    @include_occupation_details = true
    render
  end

  def create
    @rack = Ivy::HwRackServices::Create.call(rack_params.to_h)

    if @rack.persisted?
      render action: :show
    else
      render json: @rack.errors.details, status: :unprocessable_entity
    end
  end

  def update
    # XXX Replace with `load_and_authorize_resource :rack, :class => Ivy::HwRack`.
    @rack = Ivy::HwRack.find(params[:id])
    if @rack.update(rack_params)
      render action: :show
    else
      render json: @rack.errors.details, status: :unprocessable_entity
    end
  end

  #
  # DELETE /racks/1
  #
  def destroy
    # XXX Replace with `load_and_authorize_resource :rack, :class => Ivy::HwRack`.
    @rack = Ivy::HwRack.find(params[:id])
    if @rack.contains_mia?
      render json: {errors: "rack contains the Concertim device"}, status: :unprocessable_entity
    elsif !@rack.empty? && !ActiveModel::Type::Boolean.new.cast(params[:recurse])
      render json: {errors: "rack is not empty"}, status: :unprocessable_entity
    elsif @rack.destroy 
      render json: {}, status: :ok
    else
      render json: @rack.errors.details, status: :unprocessable_entity
    end
  end

  private

  #
  # rack_params
  #
  PERMITTED_PARAMS = %w[name description u_height]
  def rack_params
    if params.key?(:rack)
      params.require(:rack).permit(*PERMITTED_PARAMS)
    else
      {}
    end
  end
end
