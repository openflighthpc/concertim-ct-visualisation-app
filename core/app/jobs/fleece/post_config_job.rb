require 'faraday'

class Fleece::PostConfigJob < ApplicationJob
  queue_as :default

  def perform(config, **options)
    r = Runner.new(config, **options)
    r.call
  end

  class Result
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

  class Runner
    DEFAULT_TIMEOUT = 5

    def initialize(config, timeout:nil, test_stubs:nil)
      @config = config
      @timeout = timeout || DEFAULT_TIMEOUT
      @test_stubs = test_stubs

      if @test_stubs.present? && !Rails.env.test?
        raise ArgumentError, "test_stubs given but not test environment"
      end
    end

    def call
      response = conn.post(path, body)
      Result.new(response.success?, response.reason_phrase || "Unknown error")
    rescue Faraday::Error
      Result.new(false, $!.message)
    end

    private

    def conn
      @conn ||= Faraday.new(
        url: build_url.to_s,
      ) do |f|
          # Use the same timeout for open, read and write.
          f.options.timeout = @timeout

          f.request :json
          # f.request :retry
          # f.request :authorization, 'Bearer', @config.token

          f.response :json
          f.response :logger, Rails.logger, {
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

    def build_url
      uri = URI("")
      uri.scheme = "http"
      uri.host = @config.host_ip.to_s
      uri.port = @config.port
      uri
    end

    def path
      "/"
    end

    def body
      renderer = Rabl::Renderer.new('api/v1/fleece/configs/show', @config, {
        view_path: 'app/views',
        format: 'hash'
      })
      renderer.render
    end
  end
end
