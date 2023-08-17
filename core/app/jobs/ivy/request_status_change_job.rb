require 'faraday'

class Ivy::RequestStatusChangeJob < ApplicationJob
  queue_as :default

  def perform(target, type, action, fleece_config, user, **options)
    runner = Runner.new(
      target: target,
      type: type,
      action: action,
      user: user,
      fleece_config: fleece_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :status_code

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

    def initialize(target:, type:, action:, user:, **kwargs)
      @target = target
      @type = type
      @action = action
      @user = user
      super(**kwargs)
    end

    def call
      unless @target.valid_action?(@action)
        return Result.new(false, "#{@action} is not a valid action for #{@target.name}")
      end

      response = connection.post(url, body)

      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      Result.new(true, nil)
    rescue Faraday::Error => e
      error_message = e.message
      if e.response && e.response[:body] && e.response[:headers]['content-type']&.include?('application/json')
        message = JSON.parse(e.response[:body])["message"]
        error_message = message if message
      end
      Result.new(false, "#{error_description}: #{error_message}")
    end

    private

    def body
      {
        cloud_env:
          {
            auth_url: @fleece_config.internal_auth_url,
            user_id: (@user.root? ? @fleece_config.admin_user_id : @user.cloud_user_id).gsub(/-/, ''),
            password: @user.root? ? @fleece_config.admin_password : @user.fixme_encrypt_this_already_plaintext_password,
            project_id: @user.root? ? @fleece_config.admin_project_id : @user.project_id
          },
        action: @action
      }
    end

    def url
      "#{@fleece_config.user_handler_base_url}/update_status/#{@type}/#{@target.openstack_id}"
    end

    def error_description
      "Unable to submit request"
    end
  end
end