require 'faraday'

class Fleece::CreateClusterJob < ApplicationJob
  queue_as :default

  def perform(cluster, fleece_config, user, **options)
    runner = Runner.new(
      cluster: cluster,
      user: user,
      fleece_config: fleece_config,
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

  class Runner < Emma::Faraday::JobRunner
    def initialize(cluster:, user:, **kwargs)
      @cluster = cluster
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.post(path, body)
      Result.new(response.success?, response.reason_phrase || "Unknown error")
    rescue Faraday::Error
      Result.new(false, $!.message)
    end

    private

    def url
      @fleece_config.cluster_builder_base_url
    end

    def path
      "/clusters/"
    end

    def body
      {
        cloud_env: cloud_env_details,
        cluster: cluster_details
      }
    end

    def cluster_details
      {
        cluster_type_id: @cluster.type_id,
        name: @cluster.name,
        parameters: @cluster.field_values
      }
    end

    def cloud_env_details
      {
        auth_url: @fleece_config.internal_auth_url,
        user_id: @user.cloud_user_id,
        password: @user.fixme_encrypt_this_already_plaintext_password,
        project_id: @user.project_id
      }
    end
  end
end
