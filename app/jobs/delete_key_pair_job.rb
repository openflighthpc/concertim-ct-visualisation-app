require 'faraday'

class DeleteKeyPairJob < ApplicationJob
  queue_as :default

  def perform(key_pair_name, cloud_service_config, user, **options)
    runner = Runner.new(
      key_pair_name: key_pair_name,
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    def initialize(success, error_message, status_code=nil, private_key=nil)
      @success = !!success
      @error_message = error_message
      @private_key = private_key
      @status_code = status_code
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(key_pair_name:, user:, **kwargs)
      @key_pair_name = key_pair_name
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.delete(path) do |req|
        req.body = body
      end

      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      Result.new(true, "")
    rescue Faraday::Error
      errors = if $!.response && $!.response[:headers].fetch("Content-Type", nil) && $!.response[:headers]["Content-Type"].include?("application/json")
                 body = $!.response[:body]
                 JSON.parse(body)["message"]
               else
                 $!.message
               end
      status_code = $!.response[:status] rescue 0
      Result.new(false, errors, status_code)
    end

    private

    def url
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/key_pairs"
    end

    def body
      {
        cloud_env: cloud_env_details,
        keypair_name: @key_pair_name
      }
    end

    def cloud_env_details
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @user.cloud_user_id.gsub(/-/, ''),
        password: @user.foreign_password,
        project_id: @user.project_id
      }
    end
  end
end
