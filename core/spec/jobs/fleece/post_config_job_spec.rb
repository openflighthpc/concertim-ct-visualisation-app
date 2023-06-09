require 'rails_helper'

RSpec.describe Fleece::PostConfigJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:config) { create(:fleece_config) }

  describe "url" do
    subject { Fleece::PostConfigJob::Runner.new(config) }
    before(:each) do
      class << subject
        public :conn
        public :path
      end
    end

    it "uses the ip and port given in the config" do
      expect(subject.conn.url_prefix.to_s).to eq "http://#{config.host_ip}:#{config.port}/"
    end

    it "uses a hard-coded path" do
      expect(subject.path).to eq "/"
    end
  end

  describe "#perform" do
    context "when request is successful" do
      before(:each) do
        stubs.post("/") { |env| [ 200, {}, ""] }
      end

      it "returns a successful result" do
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result).to be_success
      end
    end

    context "when request is not successful" do
      before(:each) do
        stubs.post("/") { |env| [ 404, {}, "404 Not Found"] }
      end

      it "returns an unsuccessful result" do
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result).not_to be_success
      end

      it "returns a sensible erorr_message" do
        pending "faraday test adapter sets reason_phrase to nil"
        result = described_class.perform_now(config, test_stubs: stubs)
        expect(result.error_message).to eq "404 Not Found"
      end
    end

    context "when request timesout" do
      before(:each) do
        stubs.post("/") { |env| sleep timeout * 2 ; [ 200, {}, ""] }
      end
      let(:timeout) { 0.1 }

      it "returns an unsuccessful result" do
        result = described_class.perform_now(config, test_stubs: stubs, timeout: timeout)
        expect(result).not_to be_success
      end

      it "returns a sensible erorr_message" do
        result = described_class.perform_now(config, test_stubs: stubs, timeout: timeout)
        expect(result.error_message).to eq "execution expired"
      end
    end
  end
end
