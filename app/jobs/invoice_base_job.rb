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
      # Find the sibling Result class.  E.g., for GetInvoicesJob::Runner we
      # find GetInvoicesJob::Result.  It is a programmer error if that result
      # class is not defined.
      result_klass = self.class.module_parent.const_get(:Result)
      begin
        response =
          if Rails.application.config.fake_invoice
            fake_response
          else
            super
          end
        unless response.success?
          return result_klass.new(false, nil, nil, response.reason_phrase || "Unknown error")
        end
        return result_klass.new(true, response.body, @user, "", response.status)

      rescue Faraday::Error
        status_code = $!.response[:status] rescue 0
        result_klass.new(false, nil, nil, $!.message, status_code)
      end
    end
  end
end
