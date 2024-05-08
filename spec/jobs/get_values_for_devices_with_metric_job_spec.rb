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

RSpec.describe GetValuesForDevicesWithMetricJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:path) { "http://localhost:3000/metrics/#{ERB::Util.url_encode(metric_name)}/current" }
  let(:metric_name) { "power level" }
  subject { GetValuesForDevicesWithMetricJob::Runner.new(metric_name: metric_name, cloud_service_config: nil) }

  describe "url" do
    before(:each) do
      class << subject
        public :connection
        public :path
      end
    end

    it "uses the configured ip and port" do
      expect(subject.connection.url_prefix.to_s).to eq Rails.application.config.metric_daemon_url
    end

    it "uses the correct path" do
      expect(subject.path).to eq "/metrics/power%20level/current"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.get(path) { |env| [ 200, {}, metric_values.map(&:stringify_keys)] }
      end

      let(:metric_values) {
        [
          {id: "1", value: 32},
          {id: "2", value: 64},
        ]
      }

      let(:expected_metric_values) {
        klass = GetValuesForDevicesWithMetricJob::Result::MetricValue
        metric_values.map { |m| klass.new(**m) }.each { |m| m.id = m.id }
      }

      it "returns a successful result" do
        result = described_class.perform_now(metric_name: metric_name, test_stubs: stubs)
        expect(result).to be_success
      end

      it "makes the metrics available" do
        result = described_class.perform_now(metric_name: metric_name, test_stubs: stubs)
        expect(result.metric_values).to eq expected_metric_values
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.get(path) { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(metric_name: metric_name, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(metric_name: metric_name, test_stubs: stubs)
        expect(result.error_message).to eq "Unable to fetch metric values: the server responded with status 404"
      end
    end

    context "when request times out" do
      before(:each) do
        stubs.get(path) { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(metric_name: metric_name, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible error_message" do
        result = described_class.perform_now(metric_name: metric_name, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "Unable to fetch metric values: execution expired"
      end
    end
  end

  include_examples 'auth token header'
end
