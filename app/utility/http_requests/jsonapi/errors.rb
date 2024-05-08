#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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
