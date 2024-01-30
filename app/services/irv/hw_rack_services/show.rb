module Irv
  module HwRackServices
    class Show < Irv::HwRackServices::Index

      def self.call(rack_id, slow=false)
        new(rack_id, slow).call
      end

      def initialize(rack_id, slow)
        @rack_id = rack_id
        @slow = slow
      end

      def call
        if @slow
          @rack = HwRack.find(@rack_id)
          @rack = Api::V1::RackPresenter.new(@rack)
          renderer = Rabl::Renderer.new('api/v1/irv/racks/show', @rack, view_path: 'app/views', format: 'hash')
          renderer.render
        else
          @rack_ids = [@rack_id] # future improvement: have a different/ altered query to just get the one
          super()["Racks"]["Rack"][0]
        end
      end
    end
  end
end
