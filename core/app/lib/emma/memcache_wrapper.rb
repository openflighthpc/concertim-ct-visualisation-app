# XXX Port parts of Phoenix::Cache::Wrapper.
# * Heaters/heating/pre-heating
# * Heartbeat and reconnection.
# * Logging for requests?

module Emma
  class MemcacheWrapper
    delegate :get, :get_multi, to: :@client

    def initialize(address, options={})
      @client = Dalli::Client.new(address, options)
    end
  end
end
