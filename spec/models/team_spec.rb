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

      it "strips whitespace from name" do
        subject.name = "   space  "
        expect(subject.name).to eq "space"
      end

      it "must be unique" do
        new_team = build(:team, name: " #{subject.name}")
        expect(new_team).to have_error(:name, :taken)
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
        subject.project_id = SecureRandom.uuid
        subject.save!
        subject.reload
        expect(subject.project_id).not_to be_nil

        new_team = build(:team, project_id: subject.project_id)
        expect(new_team).to have_error(:project_id, :taken)
      end

      specify "duplicate nils are ok" do
        expect(subject.project_id).to be_nil

        new_team = build(:team, project_id: subject.project_id)
        expect(new_team).not_to have_error(:project_id, :taken)
      end

      it "strips whitespace" do
        subject.project_id = "  abc   "
        expect(subject.project_id).to eq "abc"
      end
    end

    describe "billing_acct_id" do
      it "must be unique if present" do
        subject.billing_acct_id = SecureRandom.uuid
        subject.save!
        subject.reload
        expect(subject.billing_acct_id).not_to be_nil

        new_team = build(:team, billing_acct_id: subject.billing_acct_id)
        expect(new_team).to have_error(:billing_acct_id, :taken)
      end

      specify "duplicate nils are ok" do
        expect(subject.billing_acct_id).to be_nil

        new_team = build(:team, billing_acct_id: subject.billing_acct_id)
        expect(new_team).not_to have_error(:billing_acct_id, :taken)
      end
    end

    describe "billing period dates" do
      it 'is not valid if has only a start or only an end' do
        subject.billing_period_start = Date.current
        expect(subject).to have_error(:billing_period, 'must have a start date and end date, or neither')

        subject.billing_period_end = Date.current + 2.days
        expect(subject).to be_valid

        subject.billing_period_end = nil
        expect(subject).to have_error(:billing_period, 'must have a start date and end date, or neither')

        subject.billing_period_start = nil
        expect(subject).to be_valid
      end

      it 'is not valid if end not after start' do
        subject.billing_period_start = Date.current
        subject.billing_period_end = Date.current
        expect(subject).to have_error(:billing_period_end, :greater_than)

        subject.billing_period_end = Date.current - 2.days
        expect(subject).to have_error(:billing_period_end, :greater_than)
      end

      it 'is not valid if start later than today' do
        subject.billing_period_start = Date.current + 1.month
        subject.billing_period_end = Date.current + 2.months
        expect(subject).to have_error(:billing_period_start, "must be today or earlier")
      end

      it 'is not valid if end earlier than today' do
        subject.billing_period_start = Date.current - 1.month
        subject.billing_period_end = Date.current - 2.days
        expect(subject).to have_error(:billing_period_end, "must be today or later")
      end
    end
  end
end
