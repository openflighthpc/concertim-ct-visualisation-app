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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

# Takes a template and user-provided data and creates the appropriate records
# for it. Appropriate records is a little vague, let's explain below.
#
# Simple templates
# ================
#
# If the template is simple? (i.e., it is not a blade enclosure) the
# following will be created directly by this class.
#
# * one chassis;
# * one location;
# * one device;
#
# Other records may be created as a result of those being saved, for instance
# saving the device may create a data source map, but that is outside of our
# consideration here.
#
# Complex templates
# =================
#
# Complex templates are currently not supported.  They are currently not
# required and may or may not disappear entirely.
#
module NodeServices
  class Create

    class Result < Struct.new(:chassis, :success?, :failed_record); end
    class FailedObjectNotFound < RuntimeError; end
    class UnsupportedError < RuntimeError; end

    def self.call(template, location_params, device_params, details_params, user)
      new(template, location_params, device_params, details_params, user).call
    end

    # +template+ is the Template instance that is being persisted.
    # +params+ are the params that have been gathered from the user, e.g.,
    # location and name.
    def initialize(template, location_params, device_params, details_params, user)
      @template = template
      @location_params = location_params
      @device_params = device_params
      @details_params = details_params
      @user = user
    end

    def call
      raise UnsupportedError, "complex chassis are not supported" if @template.complex?

      Rails.logger.debug("Persisting template #{@template.id}")
      Rails.logger.debug(@device_params)
      Chassis.transaction do
        create_object_graph
        @user.ability.authorize!(:update, @chassis.rack)
      end
      Result.new(@chassis, true, nil)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      Rails.logger.debug("Failed to save chassis: #{$!.message}")
      Result.new(@chassis, false, $!.record)
    end

    private

    # Build an object graph starting at Location and containing its Chassis and
    # Device.
    #
    # Ideally we would create the entire object graph in memory and then call
    # `@chassis.save!`.  Unfortunately, this doesn't work for us, as the
    # foreign keys are not propagated down the graph FSR.
    def create_object_graph
      location = Location.create!(location_params)
      @chassis = location.create_chassis!(chassis_params)

      details_class = @details_params[:type]
      details = details_class.constantize.new(@details_params.except(:type))

      device = @chassis.create_device!(@device_params.merge(details: details))

      Rails.logger.debug("Built object graph") {
        {chassis: @chassis, location: location, device: device}
      }
    end

    def location_params
      @location_params.merge(
        u_height: @template.height,
        u_depth: @template.depth,
        )
    end

    def chassis_params
      {template: @template}
    end
  end
end
