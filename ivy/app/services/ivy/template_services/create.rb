#
# Attempts to build and save a new Template based on the passed-in parameters.
#
module Ivy
  module TemplateServices
    class Create

      def self.call(params)
        new.call(params)
      end

      def call(params)
        template = build_template(params)
        template.save
        template
      end

      private

      def build_template(params)
        template = Template.new(
          name: params[:name],
          description: params[:description],
          height: params[:height],
          depth: 2,
          version: params[:version] || 1,
          chassis_type: 'Server',
          rackable: 'rackable',
          simple: true,
          rows: 1,
          columns: 1,

          # Needed for IRV structure.  Should be removed eventually.
          model: nil,
          rack_repeat_ratio: nil,
        )

        # For now we have hard-coded images and padding.  We should support
        # users uploading their images here.
        template.images = images_from_height(template.height)
        template.padding_left = 0
        template.padding_bottom = 0
        template.padding_right = 1
        template.padding_top = 0

        template
      end

      IMAGES_BY_HEIGHT = {
        1 => {front: "small-front.png", rear: "small-rear.png"},
        2 => {front: "medium-front.png", rear: "medium-rear.png"},
        3 => {front: "large-front.png", rear: "large-rear.png"},
        4 => {front: "xlarge-front.png", rear: "xlarge-rear.png"},
      }.freeze
      def images_from_height(height)
        IMAGES_BY_HEIGHT[height]
      end
    end
  end
end
