require 'faraday'

class Fleece::PostCreateClusterJob < ApplicationJob
  queue_as :default

  def perform(cluster, config, user, **options)
    r = Runner.new(cluster, config, user, **options)
    r.call
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

  class Runner
    DEFAULT_TIMEOUT = 5

    def initialize(cluster, config, user, timeout:nil, test_stubs:nil)
      @cluster = cluster
      @config = config
      @user = user
      @timeout = timeout || DEFAULT_TIMEOUT
      @test_stubs = test_stubs

      if @test_stubs.present? && !Rails.env.test?
        raise ArgumentError, "test_stubs given but not test environment"
      end
    end

    def call
      response = conn.post(path, body)
      Result.new(response.success?, response.body || "Unknown error")
    rescue Faraday::Error
      Result.new(false, $!.message)
    end

    private

    def conn
      @conn ||= Faraday.new(
        url: URI(@config.cluster_builder_base_url).to_s,
        ) do |f|
        # Use the same timeout for open, read and write.
        f.options.timeout = @timeout

        f.request :json
        # f.request :retry
        # f.request :authorization, 'Bearer', @config.token

        f.response :json
        f.response :logger, Rails.logger, {
          formatter: Emma::FaradayLogFormatter,
          headers: {request: true, response: true, errors: false},
          bodies: true,
          errors: true
        } do |logger|
          logger.filter(/("password"\s*:\s*)("[^"]*")/, '\1"[FILTERED]"')
        end

        if @test_stubs
          f.adapter(:test, @test_stubs)
        end
      end
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
      cloud_env = {
        auth_url: @config.auth_url,
        user_domain_name: @config.domain_name,
        project_domain_name: @config.domain_name
      }
      cloud_env[:username] = @user.root ? @config.username : @user.login
      cloud_env[:password] = @user.root ? @config.password : @user.cluster_builder_password
      cloud_env[:project_name] = @user.root ? @config.project_name : @user.project_id
      cloud_env

      # renderer = Rabl::Renderer.new('api/v1/fleece/configs/show', @config, {
      #   view_path: 'app/views',
      #   format: 'hash'
      # })
      # renderer.render
    end
  end
end
