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
      )
      expect(user).to be_valid
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

    it "is not valid without an email" do
      subject.email = nil
      expect(subject).to have_error(:email, :blank)
    end

    it "is not valid without a password" do
      # Need to build this user differently, because of encrypted passwords.
      user = build(:user, password: nil)
      expect(user).to have_error(:password, :blank)
    end

    describe "login" do
      it "is not valid without a login" do
        subject.login = nil
        expect(subject).to have_error(:login, :blank)
      end

      it "is not valid if too long" do
        subject.login = "a" * 81
        expect(subject).to have_error(:login, :too_long)
      end

      it "must be unique" do
        new_user = build(:user, login: user.login)
        expect(new_user).to have_error(:login, :taken)
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
  end
end
