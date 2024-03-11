require 'faraday'

class CreateTeamJob < ApplicationJob
  queue_as :default

  retry_on ::Faraday::Error, wait: :polynomially_longer, attempts: 10
  retry_on ::ActiveModel::ValidationError, wait: :polynomially_longer, attempts: 10

  def perform(team, cloud_service_config, **options)
    if team.deleted_at
      logger.info("Skipping job; team was deleted at #{team.deleted_at.inspect}")
      return
    end
    runner = Runner.new(
      team: team,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    include HttpRequests::ResultSyncer

    property :project_id, context: :cloud
    validates :project_id, presence: true, on: :cloud

    property :billing_acct_id, context: :billing
    validates :billing_acct_id, presence: true, on: :billing
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(team:, **kwargs)
      @team = team
      super(**kwargs)
    end

    def call
      response = super
      result = Result.from(response.body)
      result.validate!(:cloud)
      result.sync(@team, :cloud)
      result.validate!(:billing)
      result.sync(@team, :billing)
    rescue ::ActiveModel::ValidationError
      @logger.warn("Failed to sync response to team: #{$!.message}")
      raise
    end

    private

    def url
      "#{@cloud_service_config.user_handler_base_url}/team"
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @cloud_service_config.admin_user_id,
          password: @cloud_service_config.admin_foreign_password,
          project_id: @cloud_service_config.admin_project_id,
        },
        name: @team.name
      }.tap do |h|
        h[:project_id] = @team.project_id unless @team.project_id.blank?
        h[:billing_account_id] = @team.billing_acct_id unless @team.billing_acct_id.blank?
      end
    end
  end
end
