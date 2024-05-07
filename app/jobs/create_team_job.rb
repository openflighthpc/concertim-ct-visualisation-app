#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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
        h[:billing_acct_id] = @team.billing_acct_id unless @team.billing_acct_id.blank?
      end
    end
  end
end
