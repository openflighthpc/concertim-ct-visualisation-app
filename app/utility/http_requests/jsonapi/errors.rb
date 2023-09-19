module HttpRequests
  module Jsonapi
    class InvalidError < RuntimeError; end

    # Represents a collection of errors parsed from a JSON:API response.
    class Errors
      include Enumerable

      # Parse a JSON:API response body and return a collection of errors or
      # `nil` if no errors are present.
      def self.parse(body)
        body = JSON.parse(body) if body.is_a?(String)
        return nil if body["errors"].nil?
        new.tap do |errors|
          body["errors"].each do |error|
            errors.add(Error.parse(error))
          end
        end
      end

      attr_reader :errors

      def initialize
        @errors = []
      end

      def add(error)
        @errors << error
      end

      def each(&block)
        errors.each(&block)
      end

      # Return all the detail for all the messages in an array.
      def full_details
        map { |e| e.detail }
      end
    end

    # Represents a single error from a JSON:API error response.
    class Error
      # The subset of properties that we expect in an error object.
      PROPS = %w(detail source status title)
      def self.parse(error_hash)
        if (PROPS & error_hash.keys).empty?
          raise InvalidError, "does not contain any supported keys"
        end
        new(error_hash)
      end

      attr_reader :detail, :source, :status, :title

      def initialize(error_hash)
        PROPS.each do |prop|
          if error_hash.key?(prop)
            instance_variable_set(:"@#{prop}", error_hash[prop])
          end
        end
      end

      def match?(pointer)
        return false if source.nil?
        return false if source['pointer'].nil?
        source['pointer'] == pointer
      end
    end
  end
end
