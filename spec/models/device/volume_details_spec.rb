require 'rails_helper'

RSpec.describe Device::VolumeDetails, type: :model do
  let(:user) { create(:user) }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, user: user, template: rack_template) }
  let(:location) { create(:location, rack: rack) }
  let(:chassis) { create(:chassis, location: location, template: template) }

  let(:device_template) { create(:template, :device_template) }
  let(:volume_template) { create(:template, :volume_device_template) }

  let(:device) { create(:device, chassis: chassis, details: described_class.new) }

  subject { device.details }

  describe 'validations' do
    context 'for a device using the volume template' do
      let(:template) { volume_template }

      it { is_expected.to be_valid }
    end

    context 'for a device using the compute device template' do
      let(:template) { device_template }

      it { is_expected.not_to be_valid }
      it { is_expected.to have_error :device, 'must use the `volume` template if it has a Device::VolumeDetails' }

      it 'also shows error on device' do
        expect(device).not_to be_valid
        expect(device).to have_error :details, 'is invalid'
      end
    end

  end
end
