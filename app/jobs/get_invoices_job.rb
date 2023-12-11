require 'faraday'

class GetInvoicesJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, user, **options)
    runner = Runner.new(
      user: user,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :status_code, :invoices_count

    def initialize(success, body, user, error_message, status_code=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
      @invoices_count = body["total_invoices"]
      if success? && !body["invoices"].nil?
        @invoices = body["invoices"].map { |data| parse_invoice(data, user) }
      end
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

    def success?
      @success
    end

    def invoices
      success? ? @invoices : nil
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner
    def initialize(user:, offset:, limit:, **kwargs)
      @user = user
      @offset = offset
      @limit = limit
      super(**kwargs)
    end

    def call
      response =
        if Rails.application.config.fake_invoice
          fake_response
        else
          super
        end
      unless response.success?
        return Result.new(false, nil, nil, response.reason_phrase || "Unknown error")
      end
      return Result.new(true, response.body, @user, "", response.status)

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, nil, nil, $!.message, status_code)
    end

    private

    def fake_response
      renderer = ::ApplicationController.renderer.new
      data = renderer.render(
        template: "invoices/fakes/list",
        layout: false,
      )
      body = JSON.parse(data)
      # Return a slice of all invoices just as the real API does.
      body["invoices"] = body["invoices"][@offset, @limit]
      Object.new.tap do |o|
        o.define_singleton_method(:success?) { true }
        o.define_singleton_method(:status) { 200 }
        o.define_singleton_method(:body) { body }
      end
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/list_paginated_invoices"
      url.to_s
    end

    def body
      {
        invoices: {
          billing_account_id: @user.billing_acct_id,
          offset: @offset,
          limit: @limit,
        },
      }
    end
  end
end
