require 'faraday'

class RequestStatusChangeJob < ApplicationJob
  queue_as :default

  def perform(target, type, action, cloud_service_config, user, **options)
    runner = Runner.new(
      target: target,
      type: type,
      action: action,
      user: user,
      cloud_service_config: cloud_service_config,
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

  class Runner < HttpRequests::Faraday::JobRunner

    def initialize(target:, type:, action:, user:, **kwargs)
      @target = target
      @type = type
      @rack = @target.is_a?(HwRack) ? @target : @target.rack
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
            auth_url: @cloud_service_config.internal_auth_url,
            user_id: (@user.root? ? @cloud_service_config.admin_user_id : @user.cloud_user_id),
            password: @user.root? ? @cloud_service_config.admin_foreign_password : @user.foreign_password,
            project_id: @user.root? ? @cloud_service_config.admin_project_id : @rack.team.project_id
          },
        action: @action
      }
    end

    def url
      "#{@cloud_service_config.user_handler_base_url}/update_status/#{@type}/#{@target.openstack_id}"
    end

    def error_description
      "Unable to submit request"
    end
  end
end
