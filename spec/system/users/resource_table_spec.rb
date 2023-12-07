require 'rails_helper'
require Rails.root.join("spec/support/page_objects/user_index_page")

RSpec.describe "users index page table", type: :system do
  let(:admin_password) { 'admin-password' }
  let!(:admin) { create(:user, :admin, password: admin_password) }
  let(:items_per_page) { 20 }

  before(:each) do
    SignInPage.new
      .visit_page
      .sign_in(username: admin.login, password: admin_password)
  end

  describe "pagination" do
    context "when there are 20 or fewer users" do
      let!(:users) { create_list(:user, 10) }

      it "lists all users" do
        uip = UserIndexPage.new
          .visit_page

        users.each do |user|
          uip.assert_table_contains_user(user)
        end
      end

      it "displays disabled pagination controls 2" do
        uip = UserIndexPage.new
          .visit_page
        uip.pagination
          .assert_paginated(from: 1, to: 11, of: 11)
          .assert_link(:prev, :disabled)
          .assert_link(:next, :disabled)
      end
    end

    context "when there are more than 20 users" do
      let!(:users) { create_list(:user, 30) }

      it "lists the first 20 users 2" do
        uip = UserIndexPage.new
        uip.visit_page

        users = User.all.order(:id).offset(0).limit(items_per_page)
        users.each do |user|
          uip.assert_table_contains_user(user)
        end
      end

      it "displays enabled pagination controls" do
        uip = UserIndexPage.new
          .visit_page

        uip.pagination
          .assert_link(:prev, :disabled)
          .assert_link(:next, :enabled)
      end

      it "allows navigating to the next page 2" do
        uip = UserIndexPage.new
          .visit_page

        # Users expected to be on second page are not displayed.
        second_page_users = User.all.order(:id).offset(items_per_page).limit(items_per_page)
        second_page_users.each do |user|
          uip.assert_not_table_contains_user(user)
        end

        uip.pagination
          .assert_link(:prev, :disabled)
          .assert_link(:next, :enabled)

        uip.pagination
          .click_link "Next"

        # Users expected to be on second page are displayed.
        second_page_users.each do |user|
          uip.assert_table_contains_user(user)
        end

        uip.pagination
          .assert_link(:prev, :enabled)
          .assert_link(:next, :disabled)
      end

      it "allows navigating to the prev page" do
        uip = UserIndexPage.new
          .visit_page(page: 2)

        # Users expected to be on first page are not displayed.
        first_page_users = User.all.order(:id).offset(0).limit(items_per_page)
        first_page_users.each do |user|
          uip.assert_not_table_contains_user(user)
        end

        uip.pagination
          .assert_link(:prev, :enabled)
          .assert_link(:next, :disabled)

        uip.pagination
          .click_link "Prev"

        # Users expected to be on first page are displayed.
        first_page_users.each do |user|
          uip.assert_table_contains_user(user)
        end

        uip.pagination
          .assert_link(:prev, :disabled)
          .assert_link(:next, :enabled)
      end
    end
  end

  describe "sorting" do
    before(:each) do
      create_list(:user, items_per_page)
      create(:user, login: 'AAA') # Create a user with an "earlier" login, but later id.
      create(:user, login: 'ZZZ')
      create_list(:user, items_per_page)
    end


    it "sorts by id by default" do
      visit users_path
      expected_users = User.all.order(id: :asc).offset(0).limit(items_per_page)
      table = find('.resource_table')

      expected_users.each_with_index do |user, idx|
        expect(table).to have_css("tr:nth-child(#{idx + 1})", text: user.login)
      end
    end

    it "allows sorting in reverse order" do
      visit users_path
      table = find('.resource_table')
      header = table.find('thead')
      header.click_link "Id"

      expected_users = User.all.order(id: :desc).offset(0).limit(items_per_page)
      expected_users.each_with_index do |user, idx|
        expect(table).to have_css("tr:nth-child(#{idx + 1})", text: user.login)
      end
    end

    it "allows sorting by another column" do
      expected_users = User.all.order(login: :asc).offset(0).limit(items_per_page)
      # Let's make sure we're not just retesting the default behaviour.
      expect(expected_users.map(&:id)).not_to eq User.all.order(:id).map(&:id)

      visit users_path
      table = find('.resource_table')
      header = table.find('thead')
      header.click_link "Username"

      expected_users.each_with_index do |user, idx|
        expect(table).to have_css("tr:nth-child(#{idx + 1})", text: user.login)
      end
    end

    it "respects both sort order and pagination" do
      visit users_path
      table = find('.resource_table')

      expect(table).not_to have_content('AAA')
      expect(table).not_to have_content('ZZZ')

      header = table.find('thead')
      header.click_link "Username"

      table = find('.resource_table')
      expect(table).to have_content('AAA')
      expect(table).not_to have_content('ZZZ')

      click_link "Next"

      table = find('.resource_table')
      expect(table).not_to have_content('AAA')
      expect(table).not_to have_content('ZZZ')

      click_link "Next"
      table = find('.resource_table')
      expect(table).not_to have_content('AAA')
      expect(table).to have_content('ZZZ')
    end
  end

  describe "searching" do
    before(:each) do
      create_list(:user, items_per_page)
      create(:user, login: 'wanted-1')
      create(:user, login: 'wanted-2')
    end

    it "allows filtering for users" do
      visit users_path
      table = find('.resource_table')

      # The table displays 20 users and none are the wanted ones.
      expect(table.all('tbody tr').count).to eq 20
      expect(table).not_to have_content('wanted-1')
      expect(table).not_to have_content('wanted-2')

      controls = find('.search_controls')
      within(controls) do
        fill_in "Search", with: 'wanted'
        click_on "Go"
      end

      # The table displays the wanted users and no others.
      expect(table).to have_content('wanted-1')
      expect(table).to have_content('wanted-2')
      expect(table.all('tbody tr').count).to eq 2
    end
  end
end
