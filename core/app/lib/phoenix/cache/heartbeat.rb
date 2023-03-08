module Phoenix
  module Cache
    # Monitors a Dalli client and runs an on connection callback when
    # connected.
    class Heartbeat
      # +client+ the memcache client.
      # +logger+ the logger instance to use.
      def initialize(client, logger, frequency)
        @client = client
        @logger = logger
        @frequency = frequency
        @on_connection_callback = ->{}
      end

      # Starts a thread to monitor the memcache server.  If the connection is
      # dropped it is reset and the +on_connection+ callback ran.
      def start
        @logger.info("CACHE Heartbeat"){"Starting heartbeat"}
        @pinger ||= Thread.new do
          loop do
            begin
              unless ping?
                reset
              end
              sleep @frequency
            rescue
              @logger.warn("CACHE Heartbeat"){"Encountered an error during cache ping: #{$!}"}
              @logger.warn("CACHE Heartbeat"){$!}
              sleep @frequency
              retry
            end
          end
        end
      end

      def ping?
        begin
          @client.get('ping',true)
          @logger.debug("CACHE Heartbeat"){"Cache ping ok"}
          true
        rescue
          @logger.debug("CACHE Heartbeat"){"Cache ping failed"}
          false
        end
      end

      # Add an on_connection callback function. This will remove any previously
      # added callbacks.
      #
      # If currently connected, the callback is ran immediately.
      def on_connection_callback(&block)
        @logger.info("CACHE Heartbeat"){"Adding on connection callback"}
        @on_connection_callback = block

        if ping?
          on_connection
        end
      end

      def on_connection
        begin
          @logger.info("CACHE Heartbeat"){"Running on_connection callback"}
          @on_connection_callback.call
        rescue Dalli::NetworkError
          # reraise memcache errors - no point heating if we've got memcache issues
          @logger.warn("CACHE Heartbeat"){"on_connection callback failed"}
          raise
        rescue
          # we ignore anything that's not a memcache error, but we do log it
          @logger.warn("CACHE Heartbeat"){"Encountered an error during on_connection callback: #{$!}"}
          @logger.warn("CACHE Heartbeat"){$!}
        end
      end

      private

      def reset
        @logger.info("CACHE Heartbeat"){"Resetting cache"}
        @client.reset
        sleep 0.3
        when_connected do
          reheat
        end
      end

      # Runs the +on_connection+ method once when the connection
      # is re-established.
      def when_connected(&block)
        @logger.info("CACHE Heartbeat"){"Waiting for connection"}
        @reheater ||= Thread.new do
          loop do
            if ping?
              @logger.info("CACHE Heartbeat"){"Connection established..."}
              begin
                on_connection
              rescue
                # record reheater failure
                @logger.warn("CACHE Heartbeat"){"Reheat failure (#{$!})"}
                @logger.warn("CACHE Heartbeat"){$!}
              ensure
                # reset reheater so it can be performed once the connection is stable again
                @reheater = nil
                break
              end
            else
              sleep @frequency
            end
          end
        end
      end
    end
  end
end
