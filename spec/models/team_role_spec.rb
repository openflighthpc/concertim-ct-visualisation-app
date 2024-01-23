require 'rails_helper'

RSpec.describe TeamRole, type: :model do
  subject { team_role }
  let!(:team_role) { create(:team_role) }
  let(:team) { create(:team) }
  let(:user) { create(:user) }

  describe 'validations' do
    it "is valid with valid attributes" do
      role = described_class.new(
        user: user,
        team: team,
        role: "member"
        )
      expect(role).to be_valid
    end

    describe "user" do
      it "is not valid without a user" do
        subject.user = nil
        expect(subject).to have_error(:user, :blank)
      end

      it "is not valid if user a super admin" do
        subject.user.root = true
        expect(subject).to have_error(:user, "must not be super admin")
      end
    end

    it "is not valid without a team" do
      subject.team = nil
      expect(subject).to have_error(:team, :blank)
    end

    describe "role" do
      it "is not valid without a role" do
        subject.role = nil
        expect(subject).to have_error(:role, :blank)
      end

      it "it not valid with an unsupported role" do
        subject.role = "viewer"
        expect(subject).to have_error(:role, :inclusion)
      end
    end

    it "must be a unique user team combination" do
      new_role = build(:team_role, team: subject.team, user: subject.user)
      expect(new_role).to have_error(:user_id, :taken)
      new_role.team = team
      expect(new_role).to be_valid
    end
  end
end
