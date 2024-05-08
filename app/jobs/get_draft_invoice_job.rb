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

require 'faraday'

class GetDraftInvoiceJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, team, **options)
    runner = Runner.new(
      team: team,
      cloud_service_config: cloud_service_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result < InvoiceBaseJob::Result
    validate do
      unless @invoice.is_a?(Invoice) && @invoice.valid?
        errors.add(:invoice, message: "failed to parse")
      end
    end

    def invoice
      success? ? @invoice : nil
    end

    private

    def parse_body(body)
      @invoice = parse_invoice(body["draft_invoice"])
    end

  end

  class Runner < InvoiceBaseJob::Runner
    def initialize(team:, **kwargs)
      @team = team
      super(**kwargs)
    end

    private

    def process_response(response)
      if response.status == 204
        result_klass.new(false, nil, "Nothing to generate", response.status)
      else
        super
      end
    end

    def fake_response
      renderer = ::ApplicationController.renderer.new
      data = renderer.render(
        template: "invoices/fakes/draft",
        layout: false,
        locals: {account_id: @team.billing_acct_id},
      )
      build_fake_response(
        success: true,
        status: 201,
        body: {"draft_invoice" => JSON.parse(data)},
      )
    end

    def url
      url = URI(@cloud_service_config.user_handler_base_url)
      url.path = "/get_draft_invoice"
      url.to_s
    end

    def body
      {
        invoice: {
          billing_acct_id: @team.billing_acct_id,
          target_date: Date.today.to_formatted_s(:iso8601),
        },
      }
    end
  end
end
