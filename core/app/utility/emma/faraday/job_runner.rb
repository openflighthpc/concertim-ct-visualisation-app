require 'faraday'

module Emma
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
      DEFAULT_TIMEOUT = 5

      def initialize(fleece_config:, logger:nil, timeout:nil, test_stubs:nil)
        @fleece_config = fleece_config
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

      def connection
        @connection ||= ::Faraday.new(
          url: url,
        ) do |f|
            # Use the same timeout for open, read and write.
            f.options.timeout = @timeout

            f.request :json

            f.response :json
            f.response :raise_error
            f.response :logger, @logger, {
              formatter: Emma::Faraday::LogFormatter,
              headers: {request: true, response: true, errors: false},
              bodies: true,
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
