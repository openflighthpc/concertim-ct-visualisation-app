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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

require 'faraday'

class CreateClusterJob < ApplicationJob
  queue_as :default

  def perform(cluster, cloud_service_config, user, **options)
    runner = Runner.new(
      cluster: cluster,
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :status_code

    def initialize(success, error_message, status_code=nil, non_field_error=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
      @non_field_error = non_field_error
    end

    def success?
      @success
    end

    def non_field_error?
      success? ? nil : !!@non_field_error
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(cluster:, user:, **kwargs)
      @cluster = cluster
      @user = user
      super(**kwargs.reverse_merge(test_stubs: test_stubs))
    end

    def test_stubs
      nil
    end

    def call
      response = connection.post(path, body)
      Result.new(response.success?, response.reason_phrase || "Unknown error", response.status)

    rescue Faraday::BadRequestError
      errors = HttpRequests::Jsonapi::Errors.parse($!.response_body)
      non_field_error = merge_errors_to_fields(errors)
      error_message = errors.full_details.to_sentence
      Result.new(false, error_message, $!.response[:status], non_field_error)

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, $!.message, status_code)
    end

    private

    def url
      @cloud_service_config.cluster_builder_base_url
    end

    def path
      "/clusters/"
    end

    def body
      {
        cloud_env: cloud_env_details,
        cluster: cluster_details,
        billing_account_id: @cluster.team.billing_acct_id,
        middleware_url: @cloud_service_config.user_handler_base_url,
      }
    end

    def cluster_details
      {
        cluster_type_id: @cluster.type_id,
        name: @cluster.name,
        parameters: @cluster.field_values,
        selections: @cluster.selections,
      }
    end

    def cloud_env_details
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @user.cloud_user_id,
        password: @user.foreign_password,
        project_id: @cluster.team.project_id
      }
    end

    # For any errors that can be mapped to a cluster field, add an error on
    # that field.  Return true if there are any errors that cannot be mapped to
    # a cluster field.
    def merge_errors_to_fields(errors)
      non_field_error_found = false
      field_pointers = @cluster.fields.map { |f| ["/cluster/parameters/#{f.id}", f] }
      errors.each do |error|
        is_field_error = false
        field_pointers.each do |fp|
          if error.match?(fp.first)
            @cluster.add_field_error(fp.last, error.detail)
            is_field_error = true
            break
          end
        end
        non_field_error_found = true unless is_field_error
      end
      non_field_error_found
    end
  end
end
