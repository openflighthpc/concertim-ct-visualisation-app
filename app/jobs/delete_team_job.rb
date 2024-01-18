require 'faraday'

class DeleteTeamJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :default
  RETRY_ATTEMPTS = 10
  retry_on ::Faraday::Error, wait: :exponentially_longer, attempts: RETRY_ATTEMPTS

  # Allow only a single job for a given team and cloud platform.  Otherwise the
  # admin hammering the delete button will cause concertim to hammer the
  # middleware.
  good_job_control_concurrency_with(
    perform_limit: 1,
    enqueue_limit: 1,
    key: ->{ [self.class.name, arguments[0].to_gid.to_s, arguments[1].to_gid.to_s].join('--') },
    )

  def perform(team, cloud_service_config, **options)
    # If the team doesn't have any project or billing IDs we can just delete it
    # without involving the middleware.
    if team.project_id.nil? && team.billing_acct_id.nil?
      team.destroy!
      return
    end
    runner = Runner.new(
      team: team,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
    nil
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(team:, **kwargs)
      @team = team
      super(**kwargs.reverse_merge(test_stubs: test_stubs))
    end

    def test_stubs
      nil
    end

    def call
      response = connection.delete("") do |request|
        request.body = body
      end
      if response.success?
        @team.destroy!
      end
    end

    private

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/delete_team"
      url.to_s
    end

    def body
      {
        cloud_env: {
          auth_url: @cloud_service_config.internal_auth_url,
          user_id: @cloud_service_config.admin_user_id,
          password: @cloud_service_config.admin_foreign_password,
          project_id: @cloud_service_config.admin_project_id,
        },
        team_info: {
          billing_acct_id: @team.billing_acct_id,
          project_id: @team.project_id,
        }
      }
    end
  end
end
