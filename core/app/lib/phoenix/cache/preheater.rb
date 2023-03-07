require 'singleton'

module Phoenix
  module Cache

    #
    # Encapsulates preheating memcache.
    #
    # To use:
    #
    #    class Foo < Phoenix::Cache::Preheater
    #      heatables :MyModel1, :MyModel2
    #      cache_wrapper Phoenix::Cache::Wrapper.new('localhost:11211')
    #      logger Phoenix::Logger.new('my_log_file.log')
    #    end
    #
    #    Foo.safely_preheat
    #
    class Preheater
      include Singleton

      # Class methods implmenent a simple DSL.
      class << self
        #
        # Set the models which need to perform some preheating.
        #
        # If the method which causes the preheating to take place is called
        # preheat_interchange, add an entry in the form:
        #
        #    heatables(
        #      :MyModel1,
        #      :MyModel2
        #    )
        #
        # If some (or all) of the methods are not called preheat_interchange, the
        # call should look like:
        #
        #    heatables(
        #      :MyModel1,
        #      [:MyModel2, :badly_named_method]
        #    )
        #
        # Syntactic vinegar for all those who dare name the method badly hahahahahahahahahaha.
        #
        def heatables(*hs)
          return @heatables if hs.empty?
          @heatables ||= {}
          hs.each do |h|
            case h
            when Array
              model = h.first
              method = h.last || :preheat_interchange
            when Symbol
              model = h
              method = :preheat_interchange
            else
              raise
            end
            @heatables[model] = method
          end
        end

        # Set or retrieve the logger.
        def logger(l=nil)
          return @logger if l.nil?
          @logger = l
        end

        # Set or retrieve the Phoenix::Cache::Wrapper.
        def cache_wrapper(cw=nil)
          return @cache_wrapper if cw.nil?
          @cache_wrapper = cw
        end

        def safely_preheat(mod = nil)
          instance.safely_preheat(mod)
        end
      end

      def safely_preheat(mod = nil)
        begin
          @mod = mod
          cache_wrapper.on_connection_callback do
            heat
          end
        rescue
          logger.error $!
          STDERR.puts "cache.log: #{$!}"
        end
        nil
      end

      private

      def obj
        @mod || Object
      end

      def heat
        logger.info "Performing interchange heating..."
        heatables.each do |model, method|
          begin
            logger.debug "Heating #{model}"
            obj.const_get(model).send(method)
          rescue
            logger.warn "EXCEPTION whilst heating #{model}: #{$!.message}  #{$!.backtrace.join('   ')}"
          end
        end
        logger.info "Interchange heating completed"
      end

      def heatables
        self.class.heatables
      end

      def cache_wrapper
        self.class.cache_wrapper
      end

      def logger
        self.class.logger
      end
    end
  end
end
