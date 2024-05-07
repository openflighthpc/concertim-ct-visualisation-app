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
require 'faraday/follow_redirects'

module HttpRequests
  module Faraday

    # JobRunner makes a HTTP(S) POST request and returns the response.
    #
    # The URL and the body can be configured by subclassing and overriding the
    # `url` and `body` methods.
    #
    # Post processing the of the response can be configured by overriding the
    # `call` method, see `call` for details.
    #
    # If the connection fails a `::Faraday::Error` will be raised.  A
    # `::Faraday::Error` is also raised for `4xx` and `5xx` responses.  If
    # `JobRunner` is being used from an `ActiveJob::Base`, the request can be
    # retried by adding `retry_on ::Faraday::Error, ...` to the `ActiveJob` class.
    #
    class JobRunner
      DEFAULT_TIMEOUT = 60

      def initialize(cloud_service_config:, logger:nil, timeout:nil, test_stubs:nil)
        @cloud_service_config = cloud_service_config
        @timeout = timeout || DEFAULT_TIMEOUT
        @logger = logger || GoodJob.logger
        @test_stubs = test_stubs

        if @test_stubs.present? && !Rails.env.test?
          raise ArgumentError, "test_stubs given but not test environment"
        end
      end

      # Perform the HTTP(S) POST request and return the response.
      #
      # Post processing of the response can be implemented, by subclassing
      # `JobRunner` and overriding `call` to call `super` and post process the
      # response, e.g.,
      #
      #   class MyJobRunner
      #     class MyResult < Struct(:success, error_message) ; end
      #
      #     def call
      #       response = super
      #       MyResult.new(response.success?, response.reason_phrase || "Unknown error")
      #     end
      #   end
      #
      def call
        response = connection.post("", body)
        response
      end

      private

      # The URL that the request will be sent to.
      def url
        raise NotImplementedError
      end

      # The body that will be sent.
      def body
        raise NotImplementedError
      end

      # Include an auth token, so receiving service can validate the
      # request is from concertim visualiser.
      def auth_token
        payload = { "exp" => Time.now.to_i + 60 }
        "Bearer #{Warden::JWTAuth::TokenEncoder.new.call(payload)}"
      end

      def connection
        @connection ||= ::Faraday.new(
          url: url,
        ) do |f|
            # Use the same timeout for open, read and write.
            f.options.timeout = @timeout

            f.headers["Authorization"] = auth_token

            f.request :json

            # Follow redirects.  Preserve method for 301 and 302 status codes.
            f.response :follow_redirects, { standards_compliant: true }
            f.response :json
            f.response :raise_error
            f.response :logger, @logger, {
              formatter: HttpRequests::Faraday::LogFormatter,
              headers: {request: !Rails.env.production?, response: !Rails.env.production?, errors: false},
              bodies: !Rails.env.production?,
              errors: true
            } do |logger|
                logger.filter(/("password"\s*:\s*)("[^"]*")/, '\1"[FILTERED]"')
              end

            if @test_stubs
              f.adapter(:test, @test_stubs)
            end
          end
      end
    end
  end
end
