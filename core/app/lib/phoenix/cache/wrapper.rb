require 'phoenix/cache/heartbeat'

module Phoenix
  module Cache
    # Wrapper around a Dalli::Client providing connection monitoring and callbacks.
    class Wrapper
      delegate :add, :delete, :get, :get_multi, :set, :reset,
        to: :@client

      delegate :on_connection_callback, to: :@heartbeat

      attr_reader :logger

      def initialize(address, options={})
        logger = options.delete(:logger)
        @client = Dalli::Client.new(address, options)
        if logger.nil?
          require 'logger'
          @logger = ::Logger.new(STDERR)
        else
          @logger = logger
        end

        @logger.info("CACHE"){"Starting up ..."}
        @heartbeat = Heartbeat.new(self, @logger)

        unless @heartbeat.ping?
          @logger.warn("CACHE"){"Unable to ping memcache - is it running?"}
        end
        @heartbeat.start
      end
    end
  end
end
