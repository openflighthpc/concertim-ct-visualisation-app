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

RSpec.describe "teams index page table", type: :system do
  let(:admin_password) { 'admin-password' }
  let(:regular_user_password) { 'password' }
  let!(:admin) { create(:user, :admin, password: admin_password) }
  let(:regular_user) { create(:user, password: regular_user_password) }
  let(:items_per_page) { 20 }

  context "super admin" do
    before(:each) do
      visit new_user_session_path
      expect(current_path).to eq(new_user_session_path)
      fill_in "Username", with: admin.login
      fill_in "Password", with: admin_password
      click_on "Login"
    end

    describe "pagination" do
      context "when there are 20 or fewer teams" do
        let!(:teams) { create_list(:team, 10) }

        it "lists all teams" do
          visit teams_path
          expect(current_path).to eq(teams_path)

          table = find('.resource_table')
          teams.each do |team|
            expect(table).to have_content(team.id)
            expect(table).to have_content(team.name)
          end
        end

        it "does not display pagination controls" do
          visit teams_path
          expect(current_path).to eq(teams_path)

          controls = find('.pagination_controls')
          expect(controls).not_to have_content "Displaying"
          expect(controls).not_to have_css('.page.prev')
          expect(controls).not_to have_css('.page.next')
        end
      end

      context "when there are more than 20 teams" do
        let!(:teams) { create_list(:team, 30) }

        it "lists the first 20 teams" do
          visit teams_path
          expect(current_path).to eq(teams_path)

          table = find('.resource_table')
          teams = Team.all.order(:id).offset(0).limit(items_per_page)
          teams.each do |team|
            expect(table).to have_content(team.id)
            expect(table).to have_content(team.name)
          end
        end

        it "displays enabled pagination controls" do
          visit teams_path
          expect(current_path).to eq(teams_path)

          controls = find('.pagination_controls')
          expect(controls).to have_content "Displaying items 1-20 of 30"
          # Expect prev navigation to be disabled.
          expect(controls).to have_css('.page.prev.disabled')
          # Expect next navigation to not be disabled.
          expect(controls).not_to have_css('.page.next.disabled')
          expect(controls).to have_css('.page.next')
          expect(controls).to have_css('a[rel="next"]')
        end

        it "allows navigating to the next page" do
          visit teams_path
          expect(current_path).to eq(teams_path)
          table = find('.resource_table')
          controls = find('.pagination_controls')

          # Teams expected to be on second page are not displayed.
          second_page_teams = Team.all.order(:id).offset(items_per_page).limit(items_per_page)
          second_page_teams.each do |team|
            expect(table).not_to have_content(team.name)
          end

          # Expect prev navigation to be disabled.
          expect(controls).to have_css('.page.prev.disabled')
          # Expect next navigation to not be disabled.
          expect(controls).not_to have_css('.page.next.disabled')
          expect(controls).to have_css('.page.next')
          expect(controls).to have_css('a[rel="next"]')

          click_link "Next"
          table = find('.resource_table')
          controls = find('.pagination_controls')

          # Teams expected to be on second page are displayed.
          second_page_teams.each do |team|
            expect(table).to have_content(team.id)
            expect(table).to have_content(team.name)
          end

          # Expect prev navigation to not be disabled.
          expect(controls).not_to have_css('.page.prev.disabled')
          expect(controls).to have_css('.page.prev')
          expect(controls).to have_css('a[rel="prev"]')
          # Expect next navigation to be disabled.
          expect(controls).to have_css('.page.next.disabled')
        end

        it "allows navigating to the prev page" do
          visit teams_path(page: 2)
          expect(current_path).to eq(teams_path)
          table = find('.resource_table')
          controls = find('.pagination_controls')

          # Teams expected to be on first page are not displayed.
          first_page_teams = Team.all.order(:id).offset(0).limit(items_per_page)
          first_page_teams.each do |team|
            expect(table).not_to have_content(team.name)
          end

          # Expect prev navigation to not be disabled.
          expect(controls).not_to have_css('.page.prev.disabled')
          expect(controls).to have_css('.page.prev')
          expect(controls).to have_css('a[rel="prev"]')
          # Expect next navigation to be disabled.
          expect(controls).to have_css('.page.next.disabled')

          click_link "Prev"
          table = find('.resource_table')
          controls = find('.pagination_controls')

          # Teams expected to be on first page are displayed.
          first_page_teams.each do |team|
            expect(table).to have_content(team.id)
            expect(table).to have_content(team.name)
          end

          # Expect prev navigation to be disabled.
          expect(controls).to have_css('.page.prev.disabled')
          # Expect next navigation to not be disabled.
          expect(controls).not_to have_css('.page.next.disabled')
          expect(controls).to have_css('.page.next')
          expect(controls).to have_css('a[rel="next"]')
        end
      end
    end

    describe "sorting" do
      before(:each) do
        create_list(:team, items_per_page, :with_openstack_details)
        create(:team, project_id: '1' * 10, name: 'Team A') # Create a team with an "earlier" project id, but "later" name.
        create(:team, project_id: 'Z' * 10, name: 'Team B') # Create a team with a "later" project id, and name.
        create_list(:team, items_per_page, :with_openstack_details)
      end

      it "sorts by id by default" do
        visit teams_path
        expected_teams = Team.all.order(id: :asc).offset(0).limit(items_per_page)
        table = find('.resource_table')

        expected_teams.each_with_index do |team, idx|
          expect(table).to have_css("tr:nth-child(#{idx + 1})", text: team.name)
        end
      end

      it "allows sorting in reverse order" do
        visit teams_path
        table = find('.resource_table')
        header = table.find('thead')
        header.click_link "Id"

        expected_teams = Team.all.order(id: :desc).offset(0).limit(items_per_page)
        expected_teams.each_with_index do |team, idx|
          expect(table).to have_css("tr:nth-child(#{idx + 1})", text: team.name)
        end
      end

      it "allows sorting by another column" do
        expected_teams = Team.all.order(name: :asc).offset(0).limit(items_per_page)
        # Let's make sure we're not just retesting the default behaviour.
        expect(expected_teams.map(&:id)).not_to eq Team.all.order(:id).map(&:id)

        visit teams_path
        table = find('.resource_table')
        header = table.find('thead')
        header.click_link "Name"

        expected_teams.each_with_index do |team, idx|
          expect(table).to have_css("tr:nth-child(#{idx + 1})", text: team.name)
        end
      end

      it "respects both sort order and pagination" do
        visit teams_path(direction: :asc, sort: :name)
        table = find('.resource_table')

        expect(table).not_to have_content('Team A')
        expect(table).not_to have_content('Team B')

        header = table.find('thead')
        header.click_link "Project ID"

        table = find('.resource_table')
        expect(table).to have_content('Team A')
        expect(table).not_to have_content('Team B')

        click_link "Next"

        table = find('.resource_table')
        expect(table).not_to have_content('Team A')
        expect(table).not_to have_content('Team B')

        click_link "Next"
        table = find('.resource_table')
        expect(table).not_to have_content('Team A')
        expect(table).to have_content('Team B')
      end
    end

    describe "searching" do
      before(:each) do
        # Create enough teams to fill an entire page.  They will have names
        # such as `Team 1`, `Team 2`, etc..
        create_list(:team, items_per_page)
        # Create a couple of teams with names that sort after the earlier
        # teams.  They will not be displayed on the initial page load.
        create(:team, name: 'zzz wanted 1')
        create(:team, name: 'zzz wanted 2')
      end

      it "allows filtering for teams" do
        visit teams_path(direction: :asc, sort: :name)
        table = find('.resource_table')

        # The table displays 20 teams and none are the wanted ones.
        expect(table.all('tbody tr').count).to eq 20
        expect(table).not_to have_content('zzz wanted 1')
        expect(table).not_to have_content('zzz wanted 2')

        controls = find('.search_controls')
        within(controls) do
          fill_in "Search", with: 'wanted'
          click_on "Go"
        end

        # The table displays the wanted teams and no others.
        expect(table).to have_content('zzz wanted 1')
        expect(table).to have_content('zzz wanted 2')
        expect(table.all('tbody tr').count).to eq 2
      end

      context 'teams have users' do
        let!(:user) { create(:user, name: "Dobby") }
        let!(:team_role) { create(:team_role, user: user) }
        let!(:another_role) { create(:team_role, user: user) }

        it "allows searching for teams by user in team" do
          visit teams_path

          controls = find('.search_controls')
          within(controls) do
            fill_in "Search", with: 'Dobby'
            click_on "Go"
          end

          table = find('.resource_table')
          expect(table.all('tbody tr').count).to eq 2
          expect(table).to have_content(team_role.team.name)
          expect(table).to have_content(another_role.team.name)

          within(controls) do
            fill_in "Search", with: 'Snape'
            click_on "Go"
          end

          expect(page).to have_content('No teams have been found')
        end
      end
    end
  end

  context 'regular user' do
    before(:each) do
      visit new_user_session_path
      expect(current_path).to eq(new_user_session_path)
      fill_in "Username", with: regular_user.login
      fill_in "Password", with: regular_user_password
      click_on "Login"
    end

    context "user has no roles" do
      let!(:teams) { create_list(:team, 10) }

      it "shows no teams" do
        visit teams_path

        expect(page).to have_content('No teams have been found')
      end
    end

    context "user has some roles" do
      let!(:team) { create(:team, name: "Hufflepuff") }
      let!(:another_team) { create(:team, name: "Slytherin") }
      let!(:team_role) { create(:team_role, user: regular_user, team: team) }
      let!(:another_role) { create(:team_role, user: regular_user, team: another_team) }
      let!(:other_team) { create(:team, name: "Death Eaters") }
      let!(:other_user_role) { create(:team_role, team: other_team) }

      it "only shows user's teams" do
        visit teams_path

        table = find('.resource_table')
        expect(table.all('tbody tr').count).to eq 2
        expect(table).to have_content(team_role.team.name)
        expect(table).to have_content(another_role.team.name)
      end

      it "searches only user's teams" do
        visit teams_path

        controls = find('.search_controls')
        within(controls) do
          fill_in "Search", with: 'Hufflepuff'
          click_on "Go"
        end

        table = find('.resource_table')
        expect(table.all('tbody tr').count).to eq 1
        expect(table).to have_content(team_role.team.name)

        within(controls) do
          fill_in "Search", with: 'Death Eaters'
          click_on "Go"
        end

        expect(page).to have_content('No teams have been found')
      end
    end
  end
end
