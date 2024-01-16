require 'faraday'

class UpdateTeamRoleJob < ApplicationJob
  queue_as :default

  def perform(team_role, new_role, cloud_service_config, **options)
    runner = Runner.new(
      team_role: team_role,
      new_role: new_role,
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

    def initialize(team_role:, new_role:, **kwargs)
      @team_role = team_role
      @new_role = new_role
      super(**kwargs)
    end

    def call
      response = super

      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      if @team_role.update(role: @new_role)
        return Result.new(true, "")
      else
        return Result.new(false, "Unable to update team role: #{@team_role.errors.full_messages.join("; ")}")
      end
    rescue Faraday::Error => e
      error_message = e.message
      if e.response && e.response[:body] && e.response[:headers]['content-type']&.include?('application/json')
        message = JSON.parse(e.response[:body])["message"]
        error_message = message if message
      end
      Result.new(false, "#{error_description}: #{error_message}")
    end

    private

    def url
      "#{@cloud_service_config.user_handler_base_url}/update_team_role"
    end

    def body
      {
        cloud_env: cloud_env_details,
        team_role: team_role_details
      }
    end

    def cloud_env_details
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @cloud_service_config.admin_user_id,
        password: @cloud_service_config.admin_foreign_password,
        project_id: @cloud_service_config.admin_project_id,
      }
    end

    def team_role_details
      {
        role: @new_role,
        project_id: @team_role.team.project_id,
        user_id: @team_role.user.cloud_user_id
      }
    end

    def error_description
      "Unable to submit request"
    end
  end
end
