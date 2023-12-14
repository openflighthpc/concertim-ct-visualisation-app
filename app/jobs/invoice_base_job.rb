require 'faraday'

module InvoiceBaseJob
  class Result
    attr_reader :status_code

    def initialize(success, body, user, error_message, status_code=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
      if success? && !body.nil?
        parse_body(body, user)
      end
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end

    private

    # Called on initialization.  It should parse the body and set any needed
    # instance variables.
    def parse_body(body, user)
      raise NotImplementedError
    end

    def parse_invoice(invoice_data, user)
      Invoice.new(account: user).tap do |invoice|
        (invoice.attribute_names - %w(account items)).each do |attr|
          invoice.send("#{attr}=", invoice_data[attr] || invoice_data[attr.camelize(:lower)])
        end
        invoice_data["items"].each do |item_data|
          invoice.items << Invoice::Item.new.tap do |item|
            item.attribute_names.each do |attr|
              item.send("#{attr}=", item_data[attr] || item_data[attr.camelize(:lower)])
            end
          end
        end
      end
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(**kwargs)
      super(**kwargs)
    end

    def call
      response = send_request
      process_response(response)
    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      result_klass.new(false, nil, nil, $!.message, status_code)
    end

    private

    def send_request
      connection.post("", body)
    end

    def process_response(response)
      if response.success?
        result_klass.new(true, response.body, @user, "", response.status)
      else
        result_klass.new(false, nil, nil, response.reason_phrase || "Unknown error")
      end
    end

    def result_klass
      # Find the sibling Result class.  E.g., for GetInvoicesJob::Runner we
      # find GetInvoicesJob::Result.  It is a programmer error if that Result
      # class is not defined.
      result_klass = self.class.module_parent.const_get(:Result)
    end
  end

  module FakeInvoiceResponse
    include ActiveSupport::Concern

    private

    def send_request
      if Rails.application.config.fake_invoice
        fake_response
      else
        super
      end
    end

    # Creates a fake response for developing without needing to have our
    # middleware stack and killbill available.
    #
    # The returned object should respond to the following methods:
    #
    # * `success?` - returns true if the object fakes a successful request.
    # * `status` - the HTTP status that the response fakes.
    # * `body` - an object representing a parsed JSON body.  It should already
    #   be parsed so a Hash or an Array rather than a string.
    # * `reason_phrase` - when `success?` is false, the reason it failed.  Not
    #   needed if `success?` is true.
    #
    # The helper method `build_fake_response` can be used to return a suitable object.
    def fake_response
      raise NotImplementedError
    end

    def build_fake_response(success:, status:, body:, reason_phrase: nil)
      Object.new.tap do |o|
        o.define_singleton_method(:success?) { success }
        o.define_singleton_method(:status) { status }
        o.define_singleton_method(:body) { body }
        o.define_singleton_method(:reason_phrase) { reason_phrase }
      end
    end
  end

  if Rails.env.development?
    Runner.prepend(FakeInvoiceResponse)
  end
end
