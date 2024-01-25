require 'faraday'

class DeleteTeamRoleJob < ApplicationJob
  queue_as :default

  def perform(team_role, cloud_service_config, **options)
    runner = Runner.new(
      team_role: team_role,
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
    def initialize(team_role:, **kwargs)
      @team_role = team_role
      super(**kwargs.reverse_merge(test_stubs: test_stubs))
    end

    def test_stubs
      nil
    end

    def call
      response = connection.delete(path) do |req|
        req.body = body
      end

      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      begin
        @team_role.destroy!
        return Result.new(true, "")
      rescue ActiveRecord::RecordNotDestroyed => e
        return Result.new(false, "Unable to remove user from team: #{e.message}")
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
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/delete_team_role"
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
        role: @team_role.role,
        project_id: @team_role.team.project_id,
        user_id: @team_role.user.cloud_user_id
      }
    end

    def error_description
      "Unable to submit delete team role request"
    end
  end
end
