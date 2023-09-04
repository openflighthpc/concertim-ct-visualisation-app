require 'faraday'

class Fleece::CreateKeyPairJob < ApplicationJob
  queue_as :default

  def perform(key_pair, fleece_config, user, **options)
    runner = Runner.new(
      key_pair: key_pair,
      user: user,
      fleece_config: fleece_config,
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

  class Runner < Emma::Faraday::JobRunner
    def initialize(key_pair:, user:, **kwargs)
      @key_pair = key_pair
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.post(path, body)
      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      details = response.body["key_pair"]
      @key_pair.private_key = details["private_key"]
      @key_pair.fingerprint = details["fingerprint"]
      if @key_pair.valid?
        return Result.new(true, "")
      else
        return Result.new(false, "Unable to create keypair: #{@key_pair.errors.full_messages.join("; ")}")
      end
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
      @fleece_config.user_handler_base_url
    end

    def path
      "/key_pairs"
    end

    def body
      {
        cloud_env: cloud_env_details,
        key_pair: key_pair_details
      }
    end

    def key_pair_details
      {
        name: @key_pair.name,
        key_type: @key_pair.key_type,
        public_key: @key_pair.public_key
      }
    end

    def cloud_env_details
      {
        auth_url: @fleece_config.internal_auth_url,
        user_id: @user.cloud_user_id.gsub(/-/, ''),
        password: @user.openstack_password,
        project_id: @user.project_id
      }
    end
  end
end
