require 'faraday'

# GetCloudAssetsJob retrieves cloud assets from cluster builder such as the
# list of flavors, images and networks availabel to the given user.
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
