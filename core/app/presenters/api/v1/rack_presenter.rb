#
# Api::V1::RackPresenter
#
# Rack Presenter for the API
module Api::V1
  class RackPresenter < Emma::Presenter
    include Emma::Costed

    # Be selective about what attributes and methods we expose.
    delegate :id, :name, :u_height, :metadata, :status, :cost, :template, :rack_start_u, :rack_end_u,
      to: :o

    def devices
      @devices ||= o.devices.occupying_rack_u.map {|d| Api::V1::DevicePresenter.new(d) }
    end

    def chassis
      @chassis ||= o.chassis.map { |c|Api::V1::ChassisPresenter.new(c) }
    end

    def user
      @user ||= Api::V1::UserPresenter.new(o.user)
    end
  end
end
