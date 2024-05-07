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
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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

  describe 'teams where admin' do
    let!(:team) { create(:team) }

    context "no team roles" do
      it "returns empty" do
        expect(user.teams_where_admin).to eq []
      end
    end

    context "with member role" do
      let!(:role) { create(:team_role, user: user, team: team, role: "member") }

      it "returns empty" do
        expect(user.teams_where_admin).to eq []
      end

      context "team has other users with roles" do
        let!(:other_users_role) { create(:team_role, team: team, role: "member") }
        let!(:another_users_role) { create(:team_role, team: team, role: "admin") }

        it "returns empty" do
          expect(user.teams_where_admin).to eq []
        end
      end
    end

    context "with admin role" do
      let!(:role) { create(:team_role, user: user, team: team, role: "admin") }

      it "returns team" do
        expect(user.teams_where_admin).to eq [team]
      end

      context "with roles in other teams" do
        let!(:other_role) { create(:team_role, user: user, role: "member") }
        let!(:another_role) { create(:team_role, user: user, role: "admin") }

        it "returns all teams where admin" do
          expect(user.teams_where_admin.sort).to eq [team, another_role.team].sort
        end
      end
    end
  end
end
