require 'rails_helper'

RSpec.describe CreateTeamJob, type: :job do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:cloud_service_config) { create(:cloud_service_config) }
  let(:team) { create(:team) }

  subject(:job_runner) {
    CreateTeamJob::Runner.new(team: team, cloud_service_config: cloud_service_config, test_stubs: stubs)
}

  include_examples 'creating team job'

  describe "skipping deleted teams" do
    let(:team) { create(:team, deleted_at: Time.current) }

    it "skips teams which have already been deleted" do
      expect(described_class::Runner).not_to receive(:new)
      described_class.perform_now(team, cloud_service_config, test_stubs: stubs)
    end
  end
end
