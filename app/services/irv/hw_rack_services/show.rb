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
