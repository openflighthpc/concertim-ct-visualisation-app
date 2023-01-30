require 'dalli/client'
require 'dalli/protocol/value_serializer'

# Monkey patch to always deserialize regardless of bitflags.
#
# The heuristic used by dalli to determine if the value should be deserialized
# doesn't work with our data.  We patch the `retrieve` method here so that it
# always attempts to deserialize the data.  If that results in an
# UnmarshalError, we fall back to the default behaviour.
module ForceSerializationHack
  def retrieve(value, bitflags)
    failed = false
    begin
      super(value, failed == false ? Dalli::Protocol::ValueSerializer::FLAG_SERIALIZED : bitflags)
    rescue Dalli::UnmarshalError
      raise if failed
      failed = true
      retry
    end
  end

  class Dalli::Protocol::ValueSerializer
    prepend ForceSerializationHack
  end
end

MEMCACHE = Emma::MemcacheWrapper.new('localhost:11211', {serializer: Marshal})
