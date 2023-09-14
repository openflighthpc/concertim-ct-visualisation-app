require 'rails_helper'

RSpec.describe HwRack, type: :model do
  subject { rack }
  let!(:template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, user: user, template: template) }
  let!(:user) { create(:user) }

  describe 'validations' do
    it "is valid with valid attributes" do
      rack = described_class.new(
        template: template,
        user: user,
        status: 'IN_PROGRESS',
        cost: 99.99
      )
      expect(rack).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to have_error(:name, :blank)
    end

    it "is not valid without a u_height" do
      subject.u_height = nil
      expect(subject).to have_error(:u_height, :not_a_number)
    end

    it "is not valid without a u_depth" do
      subject.u_depth = nil
      expect(subject).to have_error(:u_depth, :not_a_number)
    end

    it "is not valid with nil metadata" do
      subject.metadata = nil
      expect(subject).to have_error(:metadata, "Must be an object")
    end

    it "is valid with blank metadata" do
      subject.metadata = {}
      expect(subject).to be_valid
    end

    it "is not valid without a template" do
      subject.template = nil
      expect(subject).to have_error(:template, :blank)
    end

    it "is not valid without a user" do
      subject.user = nil
      expect(subject).to have_error(:user, :blank)
    end

    it "must have a unique name" do
      new_rack = build(:rack, user: user, template: template, name: subject.name)
      expect(new_rack).to have_error(:name, :taken)
    end

    it "can duplicate names for racks belonging to other users" do
      new_user = create(:user)
      new_rack = build(:rack, user: new_user, template: template, name: subject.name)
      expect(new_rack).not_to have_error(:name, :taken)
    end

    it "must be higher than highest node" do
      # Changing the height of a rack is only allowed if the new height is
      # sufficiently large to accomodate all of the nodes it contains.
      skip "implement this when we have device factories et al"
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
  end

  describe "defaults" do
    before(:each) { HwRack.destroy_all }

    context "when there are no other racks" do
      it "defaults height to 42" do
        rack = HwRack.new(u_height: nil, user: user)
        expect(rack.u_height).to eq 42
      end

      it "defaults name to Rack-1" do
        rack = HwRack.new(user: user)
        expect(rack.name).to eq "Rack-1"
      end
    end

    context "when there are other racks for other users" do
      let(:other_user) { create(:user) }

      let!(:existing_rack) {
        create(:rack, u_height: 24, name: 'MyRack-2', template: template, user: other_user)
      }

      it "defaults height to 42" do
        rack = HwRack.new(u_height: nil, user: user)
        expect(rack.u_height).to eq 42
      end

      it "defaults name to Rack-1" do
        rack = HwRack.new(user: user)
        expect(rack.name).to eq "Rack-1"
      end
    end

    context "when there are other racks for this user" do
      let!(:existing_rack) {
        create(:rack, u_height: 24, name: 'MyRack-2', template: template, user: user)
      }

      it "defaults height to existing racks height" do
        rack = HwRack.new(u_height: nil, user: user)
        expect(rack.u_height).to eq 24
      end

      it "defaults name to increment of existing racks name" do
        rack = HwRack.new(user: user)
        expect(rack.name).to eq 'MyRack-3'
      end
    end
  end
end
