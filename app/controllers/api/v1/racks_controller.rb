class Api::V1::RacksController < Api::V1::ApplicationController
  load_and_authorize_resource :rack, :class => HwRack

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
    @rack = HwRack.new(rack_params)
    @rack.save

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

  PERMITTED_PARAMS = %w[name description u_height status cost creation_output] << {metadata: {}, network_details: {}}
  def rack_params
    permitted = PERMITTED_PARAMS.dup.tap do |a|
      a << :order_id if current_user.root?
      a << :team_id  if params[:action] == 'create'
    end
    params.fetch(:rack).permit(*permitted)
  end
end
