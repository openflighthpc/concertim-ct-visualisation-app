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

class CreateKeyPairJob < ApplicationJob
  queue_as :default

  def perform(key_pair, cloud_service_config, user, project_id, **options)
    runner = Runner.new(
      key_pair: key_pair,
      user: user,
      project_id: project_id,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    def initialize(success, error_message, status_code=nil, private_key=nil)
      @success = !!success
      @error_message = error_message
      @private_key = private_key
      @status_code = status_code
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(key_pair:, user:, project_id:, **kwargs)
      @key_pair = key_pair
      @user = user
      @project_id = project_id
      super(**kwargs)
    end

    def call
      response = connection.post(path, body)
      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      details = response.body["key_pair"]
      @key_pair.private_key = details["private_key"]
      @key_pair.fingerprint = details["fingerprint"]
      if @key_pair.valid?
        return Result.new(true, "")
      else
        return Result.new(false, "Unable to create keypair: #{@key_pair.errors.full_messages.join("; ")}")
      end
    rescue Faraday::Error
      errors = if $!.response && $!.response[:headers].fetch("Content-Type", nil) && $!.response[:headers]["Content-Type"].include?("application/json")
        body = $!.response[:body]
        JSON.parse(body)["message"]
      else
        $!.message
      end
      status_code = $!.response[:status] rescue 0
      Result.new(false, errors, status_code)
    end

    private

    def url
      @cloud_service_config.user_handler_base_url
    end

    def path
      "/key_pairs"
    end

    def body
      {
        cloud_env: cloud_env_details,
        key_pair: key_pair_details
      }
    end

    def key_pair_details
      {
        name: @key_pair.name,
        key_type: @key_pair.key_type,
        public_key: @key_pair.public_key
      }
    end

    def cloud_env_details
      {
        auth_url: @cloud_service_config.internal_auth_url,
        user_id: @user.cloud_user_id,
        password: @user.foreign_password,
        project_id: @project_id
      }
    end
  end
end
