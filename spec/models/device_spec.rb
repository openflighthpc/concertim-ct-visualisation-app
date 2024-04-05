require 'rails_helper'

RSpec.describe Device, type: :model do
  let!(:rack_template) { create(:template, :rack_template) }
  subject { device }
  let(:device) { create(:device, chassis: chassis) }
  let(:chassis) { create(:chassis, location: location, template: device_template) }
  let(:location) { create(:location, rack: rack) }
  let!(:rack) { create(:rack, template: rack_template) }
  let(:user) { create(:user, :as_team_member, team: rack.team) }
  let(:device_template) { create(:template, :device_template) }

  describe 'validations' do
    it "is valid with valid attributes" do
      device = described_class.new(
        chassis: chassis,
        name: 'device-0',
        status: 'IN_PROGRESS',
        cost: 99.99
      )
      device.details = Device::ComputeDetails.new
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

    it "must have a unique name within its rack" do
      new_device = build(:device, chassis: chassis, name: subject.name)

      expect(new_device.name).to eq device.name
      expect(new_device).to have_error(:name, :taken)
    end

    it "can duplicate names for devices in other racks" do
      new_rack = create(:rack, template: rack_template)
      new_location = create(:location, rack: new_rack)
      new_chassis = create(:chassis, location: new_location, template: device_template)
      new_device = build(:device, chassis: new_chassis, name: subject.name)

      expect(new_device.name).to eq device.name
      expect(new_device).not_to have_error(:name)
    end

    it "is not vaild without a status" do
      subject.status = nil
      expect(subject).to have_error(:status, :blank)
    end

    it "is not vaild with an invalid status" do
      subject.status = "SNAFU"
      expect(subject).to have_error(:status, :inclusion)
    end

    it "is not valid with a negative cost" do
      subject.cost = -99
      expect(subject).to have_error(:cost, :greater_than_or_equal_to)
    end

    it "is not valid without a details model" do
      subject.details = nil
      expect(subject).to have_error(:details, :blank)
    end

    it "is not valid with a details model that is an invalid class" do
      subject.details = location
      expect(subject).to have_error(:details_type, "Must be a valid subtype of Device::Details")
      # This is a secondary error, but until we add a second Device::Details
      # subclass, this test is the only way we can assert it's returned:
      expect(subject).to have_error(:details_type, "Cannot be changed once a device has been created")
    end
  end

  describe "broadcast changes" do
    shared_examples 'rack details' do
      it 'broadcasts rack details' do
        expect { subject }.to have_broadcasted_to(user).from_channel(InteractiveRackViewChannel).with { |data|
          expect(data["action"]).to eq action
          rack_data = data["rack"]
          expect(rack_data.present?).to be true
          expect(rack_data["owner"]["id"]).to eq rack.team.id.to_s
          expect(rack_data["template"]["name"]).to eq rack.template.name
          expect(rack_data["id"]).to eq rack.id.to_s
          expect(rack_data["name"]).to eq rack.name
          expect(rack_data["cost"]).to eq "$0.00"
          if rack.reload.devices.exists?
            expect(rack_data["Chassis"]["Slots"]["Machine"]["id"]).to eq device.id.to_s
            expect(rack_data["Chassis"]["Slots"]["Machine"]["name"]).to eq device.name
          else
            expect(rack_data["Chassis"]["Slots"]).to eq nil
          end
        }
      end
    end

    context 'created' do
      let(:action) { "modified" }
      subject { device }

      include_examples 'rack details'
    end

    context 'updated' do
      let(:action) { "modified" }
      let!(:device) { create(:device, chassis: chassis) }
      subject do
        device.name = "new-name"
        device.save!
      end

      include_examples 'rack details'
    end

    context 'deleted' do
      let(:action) { "modified" }
      let!(:device) { create(:device, chassis: chassis) }
      subject { device.destroy! }

      include_examples 'rack details'
    end
  end
end
