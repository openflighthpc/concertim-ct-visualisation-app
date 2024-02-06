require 'faraday'

# GetCloudAssetsJob retrieves cloud assets from cluster builder such as the
# list of flavors, images and networks availabel to the given user.
class GetCloudAssetsJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, user, **options)
    runner = Runner.new(
      cloud_service_config: cloud_service_config,
      user: user,
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
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.post(path, body)
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
      "/resources/"
    end

    def error_description
      "Unable to retrieve cluster builder assets"
    end

    def body
      {
        cloud_env: cloud_env_details,
      }
    end

    def cloud_env_details
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @user.cloud_user_id,
        password: @user.foreign_password,
        project_id: @user.project_id
      }
    end
  end
end
