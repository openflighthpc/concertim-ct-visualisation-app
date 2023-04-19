#
# Api::V1::RackPresenter
#
# Rack Presenter for the API
module Api::V1
  class RackPresenter < Emma::Presenter
    # Be selective about what attributes and methods we expose.
    delegate :id, :name, :u_height,
      to: :o

    def devices
      @devices ||= o.devices.occupying_rack_u.map {|d| Api::V1::DevicePresenter.new(d) }
    end

    def user
      @user ||= Api::V1::UserPresenter.new(o.user)
    end
  end
end
