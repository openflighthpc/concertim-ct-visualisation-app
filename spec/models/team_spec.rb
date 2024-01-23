require 'rails_helper'

RSpec.describe Team, type: :model do
  subject { team }
  let!(:team) { create(:team) }

  describe 'validations' do
    it "is valid with valid attributes" do
      team = described_class.new(
        name: "Hufflepuff",
        cost: 99.99,
        billing_period_start: Date.current,
        billing_period_end: Date.current + 3.days
      )
      expect(team).to be_valid
    end

    describe "name" do
      it "is not valid without a name" do
        subject.name = nil
        expect(subject).to have_error(:name, :blank)
      end

      it "is not valid if too long" do
        subject.name = "a" * 57
        expect(subject).to have_error(:name, :too_long)
      end
    end

    describe "cost" do
      it "is not valid when negative" do
        subject.cost = -99
        expect(subject).to have_error(:cost, :greater_than_or_equal_to)
      end

      it "is valid with no cost" do
        subject.cost = nil
        expect(subject).to be_valid
      end
    end

    describe "credits" do
      it "is not valid with nil credits" do
        subject.credits = nil
        expect(subject).to have_error(:credits, :blank)
      end

      it "must be a number" do
        subject.credits = "not a number"
        expect(subject).to have_error(:credits, :not_a_number)
      end
    end

    describe "project_id" do
      it "must be unique if present" do
        team.project_id = SecureRandom.uuid
        team.save!
        team.reload
        expect(team.project_id).not_to be_nil

        new_team = build(:team, project_id: team.project_id)
        expect(new_team).to have_error(:project_id, :taken)
      end

      specify "duplicate nils are ok" do
        expect(team.project_id).to be_nil

        new_team = build(:team, project_id: team.project_id)
        expect(new_team).not_to have_error(:project_id, :taken)
      end
    end

    describe "billing_acct_id" do
      it "must be unique if present" do
        team.billing_acct_id = SecureRandom.uuid
        team.save!
        team.reload
        expect(team.billing_acct_id).not_to be_nil

        new_team = build(:team, billing_acct_id: team.billing_acct_id)
        expect(new_team).to have_error(:billing_acct_id, :taken)
      end

      specify "duplicate nils are ok" do
        expect(team.billing_acct_id).to be_nil

        new_team = build(:team, billing_acct_id: team.billing_acct_id)
        expect(new_team).not_to have_error(:billing_acct_id, :taken)
      end
    end

    describe "billing period dates" do
      it 'is not valid if has only a start or only an end' do
        team.billing_period_start = Date.current
        expect(team).to have_error(:billing_period, 'must have a start date and end date, or neither')

        team.billing_period_end = Date.current + 2.days
        expect(team).to be_valid

        team.billing_period_end = nil
        expect(team).to have_error(:billing_period, 'must have a start date and end date, or neither')

        team.billing_period_start = nil
        expect(team).to be_valid
      end

      it 'is not valid if end not after start' do
        team.billing_period_start = Date.current
        team.billing_period_end = Date.current
        expect(team).to have_error(:billing_period_end, :greater_than)

        team.billing_period_end = Date.current - 2.days
        expect(team).to have_error(:billing_period_end, :greater_than)
      end

      it 'is not valid if start later than today' do
        team.billing_period_start = Date.current + 1.month
        team.billing_period_end = Date.current + 2.months
        expect(team).to have_error(:billing_period_start, "must be today or earlier")
      end

      it 'is not valid if end earlier than today' do
        team.billing_period_start = Date.current - 1.month
        team.billing_period_end = Date.current - 2.days
        expect(team).to have_error(:billing_period_end, "must be today or later")
      end
    end
  end
end
