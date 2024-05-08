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

class SyncIndividualClusterTypeJob < SyncAllClusterTypesJob
  queue_as :default

  def perform(cloud_service_config, cluster_type, use_cache=true, **options)
    runner = Runner.new(
      cloud_service_config: cloud_service_config,
      cluster_type: cluster_type,
      use_cache: use_cache,
      logger: logger,
      **options
    )
    runner.call
  end

  class Runner < SyncAllClusterTypesJob::Runner

    def initialize(cluster_type:, **kwargs)
      @cluster_type = cluster_type
      super(**kwargs)
    end

    private

    def path
      "#{super}#{@cluster_type.foreign_id}"
    end

    def latest_recorded_change
      @cluster_type.version.httpdate
    end

    def sync_data(type_details)
      @cluster_type.name = type_details["title"]
      @cluster_type.description = type_details["description"]
      @cluster_type.fields = ordered_fields(type_details["parameters"])
      @cluster_type.field_groups = type_details["parameter_groups"]
      @cluster_type.version = type_details["last_modified"]
      @cluster_type.order = type_details["order"]
      @cluster_type.logo_url = type_details["logo_url"]
      @cluster_type.instructions = type_details["instructions"]
      unless @cluster_type.save
        ["Unable to update type '#{@cluster_type.descriptive_name}': #{@cluster_type.errors.full_messages.join("; ")}"]
      else
        []
      end
    end

    def error_description
      "Unable to update cluster type"
    end
  end
end
