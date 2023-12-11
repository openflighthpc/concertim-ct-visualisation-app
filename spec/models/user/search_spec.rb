require 'rails_helper'

# These specs serve as both tests for searching the user models and also as
# generic specs for the Searchable concern.
RSpec.describe User, type: :model do

  describe "search" do
    let!(:users) {
      11.times.map do |idx|
        create(:user, login: "test-user-#{idx}", name: "Test User #{idx}")
      end
    }
    let!(:alt_user) {
      create(:user, login: "alt-user", name: "This is an alternative user")
    }
    let!(:percent_in_name) {
      create(:user, name: "User with a % char in name")
    }
    let!(:percent_not_in_name) {
      create(:user, name: "User without percent char in name")
    }

    it "allows searching by login" do
      expect(users[2].login).to eq "test-user-2"
      expected_users = [users[2]]

      found_users = User.search_for("test-user-2").order(:id)

      expect(found_users.to_a).to eq expected_users
    end

    it "allows searching by name" do
      expect(users[2].name).to eq "Test User 2"
      expected_users = [users[2]]

      found_users = User.search_for("Test User 2").order(:id)

      expect(found_users.to_a).to eq expected_users
    end

    it "searches don't have to be exact" do
      found_users = User.search_for("alternative").order(:id)
      expect(found_users.to_a).to eq [alt_user]
    end

    it "searches are case insensitive" do
      found_users = User.search_for("AlTeRnAtIvE").order(:id)
      expect(found_users.to_a).to eq [alt_user]
    end

    it "searches find all matching users" do
      expect(users[1].login).to eq "test-user-1"
      expect(users[10].login).to eq "test-user-10"
      expected_users = [users[1], users[10]]

      found_users = User.search_for("test-user-1").order(:id)

      expect(found_users.to_a).to eq expected_users
    end

    it "searches escape like special chars" do
      found_users = User.search_for("% char in name").order(:id)

      expect(found_users.to_a).to eq [percent_in_name]
    end

    it "alternative columns can be specified" do
      login_search = User.search_for("test-user-2", search_scope: [:login])
      name_search = User.search_for("test-user-2", search_scope: [:name])

      expect(login_search).not_to be_empty
      expect(name_search).to be_empty
    end
  end
end
