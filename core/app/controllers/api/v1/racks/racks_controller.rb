class Api::V1::Racks::RacksController < Api::V1::Racks::BaseController
  # load_and_authorize_resource :rack, :class => Ivy::HwRack

  def index
    # XXX load_and_authorize_resource instead.
    @racks = Ivy::HwRack.all
    render
  end

  def show
    # XXX load_and_authorize_resource instead.
    @rack = Ivy::HwRack.find(params[:id])
    render
  end

  def create
    rp = rack_params.tap do |h|
      # XXX Hardcode the template id for now.  Later need to decide what
      # templates are in the new virtual world.
      h[:template_id] = Ivy::HwRack::DEFAULT_TEMPLATE_ID
    end
    @rack = Ivy::HwRackServices::Create.call(rp.to_h)

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
  PERMITTED_PARAMS = %w[name description u_height u_depth template_id]
  def rack_params
    params.require(:rack).permit(*PERMITTED_PARAMS)
  end
end
