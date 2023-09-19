#
# HwRackServices::Create
#
# Attempts to build and save a new rack based on the passed-in parameters.
#
module HwRackServices
  class Create

    def self.call(rack_params, user)
      new(rack_params, user).call
    end

    def initialize(rack_params, user)
      @rack_params = rack_params
      @creating_user = user
    end

    def call
      rack = HwRack.new(rack_params)
      rack.save
      rack
    end

    private

    def rack_params
      if @creating_user.root?
        @rack_params
      else
        @rack_params.delete(:user_id)
        @rack_params.merge(user: @creating_user)
      end
    end
  end
end
