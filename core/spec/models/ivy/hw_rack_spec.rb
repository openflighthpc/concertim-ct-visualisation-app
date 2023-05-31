require 'rails_helper'

RSpec.describe Ivy::HwRack, type: :model do
  subject { rack }
  let!(:template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, user: user, template: template) }
  let!(:user) { create(:user) }

  describe 'validations' do
    it "is valid with valid attributes" do
      rack = described_class.new(
        template: template,
        user: user,
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

    it "must have a unique name across all users" do
      new_user = create(:user)
      new_rack = build(:rack, user: new_user, template: template, name: subject.name)
      expect(new_rack).to have_error(:name, :taken)
    end

    it "must be higher than highest node" do
      # Changing the height of a rack is only allowed if the new height is
      # sufficiently large to accomodate all of the nodes it contains.
      skip "implement this when we have device factories et al"
    end
  end
end
