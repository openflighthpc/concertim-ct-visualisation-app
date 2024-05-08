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

RSpec.describe "team roles index page table", type: :system do
  let(:admin_password) { 'admin-password' }
  let!(:admin) { create(:user, :admin, password: admin_password) }
  let!(:team) { create(:team) }
  let(:items_per_page) { 20 }

  before(:each) do
    visit new_user_session_path
    expect(current_path).to eq(new_user_session_path)
    fill_in "Username", with: admin.login
    fill_in "Password", with: admin_password
    click_on "Login"
  end

  describe "pagination" do
    context "when there are 20 or fewer roles" do
      let!(:roles) { create_list(:team_role, 10, team: team) }
      let!(:other_team_roles) { create_list(:team_role, 11) }

      it "lists all roles" do
        visit team_team_roles_path(team)
        expect(current_path).to eq(team_team_roles_path(team))

        table = find('.resource_table')
        roles.each do |role|
          expect(table).to have_content(role.user.id)
          expect(table).to have_content(role.user.name)
          expect(table).to have_content(role.role)
        end
      end

      it "does not display pagination controls" do
        visit team_team_roles_path(team)
        expect(current_path).to eq(team_team_roles_path(team))

        controls = find('.pagination_controls')
        expect(controls).not_to have_content "Displaying"
        expect(controls).not_to have_css('.page.prev')
        expect(controls).not_to have_css('.page.next')
      end
    end

    context "when there are more than 20 roles" do
      let!(:more_roles) { create_list(:team_role, 30, team: team) }

      it "lists the first 20 roles" do
        visit team_team_roles_path(team)
        expect(current_path).to eq(team_team_roles_path(team))

        table = find('.resource_table')
        roles = team.team_roles.order(:id).offset(0).limit(items_per_page)
        roles.each do |role|
          expect(table).to have_content(role.user.id)
          expect(table).to have_content(role.user.name)
          expect(table).to have_content(role.role)
        end
      end

      it "displays enabled pagination controls" do
        visit team_team_roles_path(team)
        expect(current_path).to eq(team_team_roles_path(team))

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
        visit team_team_roles_path(team)
        expect(current_path).to eq(team_team_roles_path(team))
        table = find('.resource_table')
        controls = find('.pagination_controls')

        # Teams expected to be on second page are not displayed.
        second_page_roles = team.team_roles.order(:id).offset(items_per_page).limit(items_per_page)
        second_page_roles.each do |role|
          expect(table).not_to have_content(role.user.login)
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

        # Users expected to be on second page are displayed.
        second_page_roles.each do |role|
          expect(table).to have_content(role.user.id)
          expect(table).to have_content(role.user.name)
          expect(table).to have_content(role.role)
        end

        # Expect prev navigation to not be disabled.
        expect(controls).not_to have_css('.page.prev.disabled')
        expect(controls).to have_css('.page.prev')
        expect(controls).to have_css('a[rel="prev"]')
        # Expect next navigation to be disabled.
        expect(controls).to have_css('.page.next.disabled')
      end

      it "allows navigating to the prev page" do
        visit team_team_roles_path(team, page: 2)
        expect(current_path).to eq(team_team_roles_path(team))
        table = find('.resource_table')
        controls = find('.pagination_controls')

        # Roles expected to be on first page are not displayed.
        first_page_roles = team.team_roles.order(:id).offset(0).limit(items_per_page)
        first_page_roles.each do |role|
          expect(table).not_to have_content(role.user.name)
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

        # Users expected to be on first page are displayed.
        first_page_roles.each do |role|
          expect(table).to have_content(role.user.id)
          expect(table).to have_content(role.user.name)
          expect(table).to have_content(role.role)
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
      create_list(:team_role, items_per_page, team: team)
      create(:team_role, team: team, user: create(:user, name: 'ZZZ-aaa'), role: "admin")
      create_list(:team_role, items_per_page, team: team)
      create(:team_role, team: team, user: create(:user, name: 'ZZZ-ZZZ'))
    end

    it "sorts by id by default" do
      visit team_team_roles_path(team)
      expected_roles = team.team_roles.order(id: :asc).offset(0).limit(items_per_page)
      table = find('.resource_table')

      expected_roles.each_with_index do |role, idx|
        expect(table).to have_css("tr:nth-child(#{idx + 1})", text: role.user.name)
      end
    end

    it "allows sorting in reverse order" do
      visit team_team_roles_path(team, direction: :asc, sort: :user_id)
      table = find('.resource_table')
      header = table.find('thead')
      header.click_link "User"

      expected_roles = team.team_roles.order(user_id: :desc).offset(0).limit(items_per_page)
      expected_roles.each_with_index do |role, idx|
        expect(table).to have_css("tr:nth-child(#{idx + 1})", text: role.user.id)
      end
    end

    it "allows sorting by another column" do
      expected_roles = team.team_roles.order(role: :asc).offset(0).limit(items_per_page)
      # Let's make sure we're not just retesting the default behaviour.
      expect(expected_roles.map(&:role)).not_to eq team.team_roles.order(:id).map(&:role)

      visit team_team_roles_path(team)
      table = find('.resource_table')
      header = table.find('thead')
      header.click_link "Role"

      expected_roles.each_with_index do |role, idx|
        expect(table).to have_css("tr:nth-child(#{idx + 1})", text: role.user.id)
      end
    end

    it "respects both sort order and pagination" do
      visit team_team_roles_path(team, direction: :asc, sort: :role)
      table = find('.resource_table')

      expect(table).to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')

      header = table.find('thead')
      header.click_link "Role"

      table = find('.resource_table')
      expect(table).not_to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')

      click_link "Next"

      table = find('.resource_table')
      expect(table).not_to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')

      click_link "Next"
      table = find('.resource_table')
      expect(table).to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')
    end
  end

  describe "searching" do
    before(:each) do
      # Create enough roles to fill an entire page.  They will have users with names such as
      # such as `user 1`, `user 2`, etc..
      create_list(:team_role, items_per_page, team: team, role: "admin")
      # Create a couple of roles with users with role names that sort after the earlier
      # users.  They will not be displayed on the initial page load.
      create(:team_role, team: team, user: create(:user, name: 'zzz-wanted-1'), role: "member")
      create(:team_role, team: team, user: create(:user, name: 'zzz-wanted-2'), role: "member")
    end

    it "allows filtering for roles" do
      visit team_team_roles_path(team, direction: :asc, sort: :role)
      table = find('.resource_table')

      # The table displays 20 roles and none are the wanted ones.
      expect(table.all('tbody tr').count).to eq 20
      expect(table).not_to have_content('zzz-wanted-1')
      expect(table).not_to have_content('zzz-wanted-2')

      controls = find('.search_controls')
      within(controls) do
        fill_in "Search", with: 'member'
        click_on "Go"
      end

      # The table displays the wanted roles and no others.
      expect(table).to have_content('zzz-wanted-1')
      expect(table).to have_content('zzz-wanted-2')
      expect(table.all('tbody tr').count).to eq 2
    end

    it "allows searching by user's name" do
      visit team_team_roles_path(team, direction: :asc, sort: :role)
      table = find('.resource_table')

      # The table displays 20 users and none are the wanted ones.
      expect(table.all('tbody tr').count).to eq 20
      expect(table).not_to have_content('zzz-wanted-1')
      expect(table).not_to have_content('zzz-wanted-2')

      controls = find('.search_controls')
      within(controls) do
        fill_in "Search", with: 'wanted'
        click_on "Go"
      end

      # The table displays the wanted users and no others.
      expect(table).to have_content('zzz-wanted-1')
      expect(table).to have_content('zzz-wanted-2')
      expect(table.all('tbody tr').count).to eq 2
    end
  end
end
