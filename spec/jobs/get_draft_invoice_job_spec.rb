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

require 'rails_helper'

RSpec.describe GetDraftInvoiceJob, type: :job do

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team, :with_openstack_details) }

  subject(:job_runner) {
    described_class::Runner.new(team: team, cloud_service_config: cloud_service_config, test_stubs: stubs)
  }

  let(:team_invoice_path) { "/get_draft_invoice" }
  let(:expected_url) {
    "#{cloud_service_config.user_handler_base_url}#{team_invoice_path}"
  }

  describe "url" do
    subject { super().send(:url) }

    it "uses the correct ip, port and path" do
      expect(subject).to eq expected_url
    end
  end

  describe "body" do
    subject { super().send(:body).with_indifferent_access }

    it "contains invoice config" do
      expect(subject[:invoice]).to eq({
        "billing_acct_id" => team.billing_acct_id,
        "target_date" => "#{Date.today.year}-#{"%02d" % Date.today.month}-#{"%02d" % Date.today.day}",
      })
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post(expected_url) { |env| [ 200, {}, {"draft_invoice" => draft_invoice}] }
      end

      let(:draft_invoice) {
        {
          account_id: team.billing_acct_id,
          amount: 1,
          balance: 2,
          credit_adj: 0,
          currency: "coffee",
          status: 'DRAFT',
          invoice_date: Date.today.to_formatted_s(:db),
          invoice_id: 3,
          invoice_number: nil,
          items: [],
          refund_adj: 0,
        }.with_indifferent_access
      }

      it "returns a successful result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expect(result).to be_success
      end

      it "contains the invoice document in the result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expected_invoice = Invoice.new(
          account: team,
          amount: 1,
          balance: 2,
          credit_adj: 0,
          currency: "coffee",
          status: "DRAFT",
          invoice_date: Date.today,
          invoice_id: 3,
          invoice_number: nil,
          items: [],
          refund_adj: 0,
        )
        expect(result.invoice.attributes).to eq expected_invoice.attributes
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post(expected_url) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs)
        expect(result.error_message).to eq "the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.post(expected_url) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(cloud_service_config, team, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
