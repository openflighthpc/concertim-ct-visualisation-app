require 'faraday'

class GetTeamQuotasJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, team, **options)
    runner = Runner.new(
      team: team,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :quotas

    def initialize(success, quotas, error_message)
      @success = !!success
      @quotas = quotas
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

    def initialize(team:, **kwargs)
      @team = team
      super(**kwargs)
    end

    def call
      response = connection.get(path)
      unless response.success?
        return Result.new(false, {}, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end
      Result.new(true, filter_response(response.body["quotas"]), nil)
    rescue Faraday::Error
      Result.new(false, {}, "#{error_description}: #{$!.message}")
    end

    private

    def url
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/team/#{@team.project_id}/quotas"
    end

    def filter_response(quotas)
      quotas.reject {|k, v| k == "id" }
    end

    def error_description
      "Unable to retrieve team quotas"
    end
  end
end
