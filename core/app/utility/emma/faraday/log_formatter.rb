require 'faraday'

module Emma
  module Faraday
    class LogFormatter < ::Faraday::Logging::Formatter
      # Overridden to use `exc.message` instead of `exc.full_message`.
      def exception(exc)
        return unless log_errors?

        error_log = proc { exc.message }
        public_send(log_level, 'error', &error_log)

        log_headers('error', exc.response_headers) if exc.respond_to?(:response_headers) && log_headers?(:error)
        return unless exc.respond_to?(:response_body) && exc.response_body && log_body?(:error)

        log_body('error', exc.response_body)
      end
    end
  end
end
