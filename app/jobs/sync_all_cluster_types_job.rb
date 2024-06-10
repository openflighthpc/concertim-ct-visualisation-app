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

require 'faraday'

class SyncAllClusterTypesJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, use_cache=true, **options)
    runner = Runner.new(
      cloud_service_config: cloud_service_config,
      use_cache: use_cache,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    def initialize(success, error_message)
      @success = !!success
      @error_message = error_message
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner

    def initialize(use_cache:true, **kwargs)
      @use_cache = use_cache
      super(**kwargs)
    end

    def call
      connection.headers["If-Modified-Since"] = latest_recorded_change if @use_cache
      response = connection.get(path)
      if response.status == 304
        return Result.new(true, nil)
      end

      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      errors = sync_data(response.body)
      Result.new(errors.empty?, errors.join("<br>") || "Unknown error")
    rescue Faraday::Error
      Result.new(false, "#{error_description}: #{$!.message}")
    end

    private

    def url
      @cloud_service_config.cluster_builder_base_url
    end

    def path
      "/cluster-types/"
    end

    def latest_recorded_change
      ClusterType.maximum(:version)&.httpdate
    end

    def ordered_fields(fields)
      return unless fields

      fields.keys.each_with_index do |field_name, index|
        fields[field_name]["order"] = index
      end
      fields
    end

    def sync_data(types)
      errors = []
      types.each do |type_details|
        type = ClusterType.find_or_initialize_by(foreign_id: type_details["id"])
        type.name = type_details["title"]
        type.description = type_details["description"]
        type.fields = ordered_fields(type_details["parameters"])
        type.field_groups = type_details["parameter_groups"]
        type.version = type_details["last_modified"]
        type.order = type_details["order"]
        type.logo_url = type_details["logo_url"]
        type.instructions = type_details["instructions"]
        unless type.save
          errors << "Unable to #{type.persisted? ? "update" : "create"} type '#{type.descriptive_name}': #{type.errors.full_messages.join("; ")}"
        end
      end

      # Perhaps these will need to be archived instead of deleted, for data integrity
      ClusterType.where.not(foreign_id: types.map { |type| type["id"] }).each do |to_remove|
        unless to_remove.destroy
          errors << "Unable to remove type '#{to_remove.descriptive_name}': #{to_remove.errors.full_messages.join("; ")}"
        end
      end
      errors
    end

    def error_description
      "Unable to update cluster types"
    end
  end
end
