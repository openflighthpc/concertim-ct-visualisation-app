require 'rails_helper'

RSpec.describe Ivy::Device, type: :model do
  let!(:rack_template) { create(:template, :rack_template) }
  subject { device }
  let!(:device) { create(:device, chassis: chassis) }
  let(:chassis) { create(:chassis, location: location, template: device_template) }
  let(:location) { create(:location, rack: rack) }
  let(:rack) { create(:rack, user: user, template: rack_template) }
  let(:user) { create(:user) }
  let(:device_template) { create(:template, :device_template) }

  describe 'validations' do
    it "is valid with valid attributes" do
      device = described_class.new(
        chassis: chassis,
        name: 'device-0',
      )
      expect(device).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to have_error(:name, :blank)
    end

    it "is not valid with badly formatted name" do
      subject.name = "not a valid name"
      expect(subject).to have_error(:name, :invalid)
    end

    it "is not valid with nil metadata" do
      subject.metadata = nil
      expect(subject).to have_error(:metadata, "Must be an object")
    end

    it "is valid with blank metadata" do
      subject.metadata = {}
      expect(subject).to be_valid
    end

    it "is not valid without a chassis" do
      subject.chassis = nil
      expect(subject).to have_error(:chassis, :blank)
    end

    it "must have a unique name" do
      new_device = build(:device, chassis: chassis, name: subject.name)
      expect(new_device).to have_error(:name, "'#{new_device.name}' has already been taken by a Device")
    end

    it "must have a unique name across all racks" do
      new_user = create(:user)
      new_rack = create(:rack, user: new_user, template: rack_template)
      new_location = create(:location, rack: new_rack)
      new_chassis = create(:chassis, location: new_location, template: device_template)
      new_device = build(:device, chassis: new_chassis, name: subject.name)

      expect(new_device).to have_error(:name, "'#{new_device.name}' has already been taken by a Device")
    end

  end
end
