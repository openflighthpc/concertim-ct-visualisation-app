require 'rails_helper'

RSpec.describe Device::NetworkDetails, type: :model do
  let(:team) { create(:team) }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, team: team, template: rack_template) }
  let(:location) { create(:location, rack: rack) }
  let(:chassis) { create(:chassis, location: location, template: template) }

  let(:device_template) { create(:template, :device_template) }
  let(:network_template) { create(:template, :network_device_template) }

  let(:device) { create(:device, chassis: chassis, details: described_class.new) }

  subject { device.details }

  describe 'validations' do
    context 'for a device using the network template' do
      let(:template) { network_template }

      it { is_expected.to be_valid }
    end

    context 'for a device using the compute device template' do
      let(:template) { device_template }

      it { is_expected.not_to be_valid }
      it { is_expected.to have_error :device, 'must use the `network` template if it has a Device::NetworkDetails' }

      it 'also shows error on device' do
        expect(device).not_to be_valid
        expect(device).to have_error :details, 'is invalid'
      end
    end

  end
end
