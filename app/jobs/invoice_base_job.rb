require 'faraday'

module InvoiceBaseJob
  class Result
    include ActiveModel::Validations

    attr_reader :status_code

    def initialize(success, body, error_message, status_code=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
      if success && !body.nil?
        begin
          parse_body(body)
        rescue
          # We assume here that the result will not be valid? and other than
          # logging the error no further error handling is required here.
          Rails.logger.info("error parsing body: #{([$!.message]+$!.backtrace).join("\n")}")
        end
      end
    end

    # Return true if the HTTP request was successful and the body is valid.
    def success?
      @success && valid?
    end

    def error_message
      if !@success
        @error_message
      elsif !valid?
        errors.full_messages.to_sentence
      else
        nil
      end
    end

    private

    # Called on initialization.  It should parse the body and set any needed
    # instance variables.
    def parse_body(body)
      raise NotImplementedError
    end

    # Return the user that the given invoice was generated for.
    def user_for_invoice(invoice_data)
      billing_account_id = invoice_data["accountId"] || invoice_data["account_id"]
      User.find_by(billing_acct_id: billing_account_id).tap do |user|
        if user.nil?
          invoice_id = invoice_data["invoiceId"] || invoice_data["invoice_id"]
          Rails.logger.warn("Unable to find matching user for invoice. invoice_id:#{invoice_id} account_id:#{billing_account_id}")
        end
      end
    end

    def parse_invoice(invoice_data)
      Invoice.new.tap do |invoice|
        invoice.account = user_for_invoice(invoice_data)
        (invoice.attribute_names - %w(account items)).each do |attr|
          invoice.send("#{attr}=", invoice_data[attr] || invoice_data[attr.camelize(:lower)])
        end
        invoice_data["items"].each do |item_id, item_data|
          invoice.items << Invoice::Item.new.tap do |item|
            item.invoice = invoice
            (item.attribute_names - %w(invoice)).each do |attr|
              item.send("#{attr}=", item_data[attr] || item_data[attr.camelize(:lower)])
            end
          end
        end
        unless invoice.valid?
          Rails.logger.info("Failed to parse invoice #{invoice.invoice_id}: #{invoice.errors.details}")
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
      result_klass.new(false, nil, $!.message, status_code)
    end

    private

    def send_request
      connection.post("", body)
    end

    def process_response(response)
      if response.success?
        result_klass.new(true, response.body, "", response.status)
      else
        result_klass.new(false, nil, response.reason_phrase || "Unknown error")
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
