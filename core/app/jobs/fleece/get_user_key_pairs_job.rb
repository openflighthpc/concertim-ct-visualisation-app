require 'faraday'

class Fleece::GetUserKeyPairsJob < ApplicationJob
  queue_as :default

  def perform(fleece_config, user, **options)
    runner = Runner.new(
      user: user,
      fleece_config: fleece_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :key_pairs, :status_code

    def initialize(success, key_pairs, error_message, status_code=nil)
      @success = !!success
      @key_pairs = key_pairs
      @error_message = error_message
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
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.get(path) do |req|
        req.body = body
      end
      unless response.success?
        return Result.new(false, [], "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      results = response.body
      key_pairs = results["key_pairs"].map do |key_pair|
        details = key_pair["keypair"]
        Fleece::KeyPair.new(name: details["name"], fingerprint: details["fingerprint"], key_type: details["type"] || "ssh")
      end
      return Result.new(true, key_pairs, "")

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, [], $!.message, status_code)
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
        cloud_env: {
          auth_url: @fleece_config.internal_auth_url,
          user_id: @user.cloud_user_id.gsub(/-/, ''),
          password: @user.fixme_encrypt_this_already_plaintext_password,
          project_id: @user.project_id
        }
      }
    end
  end
end
