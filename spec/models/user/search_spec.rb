#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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

      found_users = User.search_for("test-user-2").order(:created_at)

      expect(found_users.to_a).to eq expected_users
    end

    it "allows searching by name" do
      expect(users[2].name).to eq "Test User 2"
      expected_users = [users[2]]

      found_users = User.search_for("Test User 2").order(:created_at)

      expect(found_users.to_a).to eq expected_users
    end

    it "searches don't have to be exact" do
      found_users = User.search_for("alternative").order(:created_at)
      expect(found_users.to_a).to eq [alt_user]
    end

    it "searches are case insensitive" do
      found_users = User.search_for("AlTeRnAtIvE").order(:created_at)
      expect(found_users.to_a).to eq [alt_user]
    end

    it "searches find all matching users" do
      expect(users[1].login).to eq "test-user-1"
      expect(users[10].login).to eq "test-user-10"
      expected_users = [users[1], users[10]].sort_by(&:created_at)

      found_users = User.search_for("test-user-1").order(:created_at)

      expect(found_users.to_a).to eq expected_users
    end

    it "searches escape like special chars" do
      found_users = User.search_for("% char in name").order(:created_at)

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
