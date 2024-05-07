#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

#
# Attempts to build and save a new Template based on the passed-in parameters.
#
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
        template_type: 'Device',
        rackable: 'rackable',
        simple: true,
        rows: 1,
        columns: 1,

        foreign_id: params[:foreign_id],
        vcpus: params[:vcpus],
        ram: params[:ram],
        disk: params[:disk],

        # Needed for IRV structure.  Should be removed eventually.
        model: nil,
        rack_repeat_ratio: nil,

        tag: params[:tag],
        # Users can't upload images here, only use existing ones (though I
        # suppose they could use fully-qualified URLs too)
        images: params[:images] || {}
      )

      if template.images.empty?
        set_images_from_height(template)
      end

      # For now we have hard-coded padding.
      set_padding_from_height(template)

      template
    end

    IMAGES_BY_HEIGHT = {
      1 => {front: "generic_front_1u.png", rear: "generic_rear_1u.png"},
      2 => {front: "generic_front_2u.png", rear: "generic_rear_2u.png"},
      3 => {front: "generic_front_3u.png", rear: "generic_rear_3u.png"},
      4 => {front: "generic_front_4u.png", rear: "generic_rear_4u.png"},
      5 => {front: "generic_front_5u.png", rear: "generic_rear_5u.png"},
      6 => {front: "generic_front_6u.png", rear: "generic_rear_6u.png"},
    }.freeze

    def set_images_from_height(template)
      img = IMAGES_BY_HEIGHT[template.height]
      template.images = img
    end

    def set_padding_from_height(template)
      # The correct padding depends on the image.  All of the images in
      # IMAGES_BY_HEIGHT require a padding of 0,0,0,0.  So that's easy.
      template.padding_left = 0
      template.padding_bottom = 0
      template.padding_right = 0
      template.padding_top = 0
    end
  end
end
