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

require 'faraday'

# GetCloudAssetsJob retrieves cloud assets from cluster builder such as the
# list of flavors, images and networks available to the given user/team.
class GetCloudAssetsJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, user, team, **options)
    runner = Runner.new(
      cloud_service_config: cloud_service_config,
      user: user,
      team: team,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :assets

    def initialize(success, assets, error_message)
      @success = !!success
      @assets = assets
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
    def initialize(user:, team:, **kwargs)
      @user = user
      @team = team
      super(**kwargs)
    end

    def call
      response = connection.get(path, params)
      unless response.success?
        return Result.new(false, {}, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end
      Result.new(true, response.body, nil)
    rescue Faraday::Error
      Result.new(false, {}, "#{error_description}: #{$!.message}")
    end

    private

    def url
      @cloud_service_config.cluster_builder_base_url
    end

    def path
      "/cloud_assets/"
    end

    def error_description
      "Unable to retrieve cluster builder assets"
    end

    def params
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @user.cloud_user_id,
        password: @user.foreign_password,
        project_id: @team.project_id
      }
    end
  end
end
