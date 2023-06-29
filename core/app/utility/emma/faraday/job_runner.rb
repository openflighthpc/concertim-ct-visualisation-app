require 'faraday'

module Emma
  module Faraday

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
            # f.request :retry

            f.response :json
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
