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
      renderer = Rabl::Renderer.new('api/v1/fleece/clusters/show', @cluster, {
        view_path: 'app/views',
        format: 'hash'
      })
      renderer.render
    end

    def cloud_env_details
      {
        auth_url: @fleece_config.auth_url,
        user_domain_name: @fleece_config.domain_name,
        project_domain_name: @fleece_config.domain_name,
        username: @user.login,
        password: @user.fixme_encrypt_this_already_plaintext_password,
        project_id: @user.project_id
      }
    end
  end
end
