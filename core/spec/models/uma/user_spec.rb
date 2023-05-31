require 'rails_helper'

RSpec.describe Uma::User, type: :model do
  subject { user }
  let!(:user) { create(:user) }

  describe 'validations' do
    it "is valid with valid attributes" do
      user = described_class.new(
        name: "name",
        email: "an@email.com",
        login: "login",
        password: "password"
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

    it "must have a unique project_id" do
      user.project_id = SecureRandom.uuid
      user.save!
      user.reload
      expect(user.project_id).not_to be_nil

      new_user = build(:user, project_id: user.project_id)
      expect(new_user).to have_error(:project_id, :taken)
    end

    specify "duplicate nil project_ids are ok" do
      expect(user.project_id).to be_nil

      new_user = build(:user, project_id: user.project_id)
      expect(new_user).not_to have_error(:project_id, :taken)
    end
  end
end

