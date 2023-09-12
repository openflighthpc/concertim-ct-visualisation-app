require 'rails_helper'

RSpec.describe User, type: :model do
  subject { user }
  let!(:user) { create(:user) }

  describe 'validations' do
    it "is valid with valid attributes" do
      user = described_class.new(
        name: "name",
        email: "an@email.com",
        login: "login",
        password: "password",
        cost: 99.99,
        billing_period_start: Date.current,
        billing_period_end: Date.current + 3.days
      )
      expect(user).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to have_error(:name, :blank)
    end

    it "is not valid without an email" do
      subject.email = nil
      expect(subject).to have_error(:email, :blank)
    end

    it "is not valid without a password" do
      # Need to build this user differently, because of encrypted passwords.
      user = build(:user, password: nil)
      expect(user).to have_error(:password, :blank)
    end

    it "is not valid without a login" do
      subject.login = nil
      expect(subject).to have_error(:login, :blank)
    end

    it "must have a unique login" do
      new_user = build(:user, login: user.login)
      expect(new_user).to have_error(:login, :taken)
    end

    it "is not valid with a negative cost" do
      subject.cost = -99
      expect(subject).to have_error(:cost, :greater_than_or_equal_to)
    end

    it "is valid with no cost" do
      subject.cost = nil
      expect(subject).to be_valid
    end

    describe "project_id" do
      it "must be unique if present" do
        user.project_id = SecureRandom.uuid
        user.save!
        user.reload
        expect(user.project_id).not_to be_nil

        new_user = build(:user, project_id: user.project_id)
        expect(new_user).to have_error(:project_id, :taken)
      end

      specify "duplicate nils are ok" do
        expect(user.project_id).to be_nil

        new_user = build(:user, project_id: user.project_id)
        expect(new_user).not_to have_error(:project_id, :taken)
      end
    end

    describe "cloud_user_id" do
      it "must be unique if present" do
        user.cloud_user_id = SecureRandom.uuid
        user.save!
        user.reload
        expect(user.cloud_user_id).not_to be_nil

        new_user = build(:user, cloud_user_id: user.cloud_user_id)
        expect(new_user).to have_error(:cloud_user_id, :taken)
      end

      specify "duplicate nils are ok" do
        expect(user.cloud_user_id).to be_nil

        new_user = build(:user, cloud_user_id: user.cloud_user_id)
        expect(new_user).not_to have_error(:cloud_user_id, :taken)
      end
    end

    describe "billing period dates" do
      it 'is not valid if has only a start or only an end' do
        user.billing_period_start = Date.current
        expect(user).to have_error(:billing_period, 'must have a start date and end date, or neither')

        user.billing_period_end = Date.current + 2.days
        expect(user).to be_valid

        user.billing_period_end = nil
        expect(user).to have_error(:billing_period, 'must have a start date and end date, or neither')

        user.billing_period_start = nil
        expect(user).to be_valid
      end

      it 'is not valid if end not after start' do
        user.billing_period_start = Date.current
        user.billing_period_end = Date.current
        expect(user).to have_error(:billing_period_end, :greater_than)

        user.billing_period_end = Date.current - 2.days
        expect(user).to have_error(:billing_period_end, :greater_than)
      end

      it 'is not valid if start later than today' do
        user.billing_period_start = Date.current + 1.month
        user.billing_period_end = Date.current + 2.months
        expect(user).to have_error(:billing_period_start, "must be today or earlier")
      end

      it 'is not valid if end earlier than today' do
        user.billing_period_start = Date.current - 1.month
        user.billing_period_end = Date.current - 2.days
        expect(user).to have_error(:billing_period_end, "must be today or later")
      end
    end
  end
end

