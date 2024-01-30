require 'rails_helper'

RSpec.describe "users index page table", type: :system do
  let(:admin_password) { 'admin-password' }
  let!(:admin) { create(:user, :admin, password: admin_password) }
  let(:items_per_page) { 20 }

  before(:each) do
    visit new_user_session_path
    expect(current_path).to eq(new_user_session_path)
    fill_in "Username", with: admin.login
    fill_in "Password", with: admin_password
    click_on "Login"
  end

  describe "pagination" do
    context "when there are 20 or fewer users" do
      let!(:users) { create_list(:user, 10) }

      it "lists all users" do
        visit users_path
        expect(current_path).to eq(users_path)

        table = find('.resource_table')
        users.each do |user|
          expect(table).to have_content(user.id)
          expect(table).to have_content(user.login)
          expect(table).to have_content(user.name)
        end
      end

      it "does not display pagination controls" do
        visit users_path
        expect(current_path).to eq(users_path)

        controls = find('.pagination_controls')
        expect(controls).not_to have_content "Displaying"
        expect(controls).not_to have_css('.page.prev')
        expect(controls).not_to have_css('.page.next')
      end
    end

    context "when there are more than 20 users" do
      let!(:users) { create_list(:user, 30) }

      it "lists the first 20 users" do
        visit users_path
        expect(current_path).to eq(users_path)

        table = find('.resource_table')
        users = User.all.order(:id).offset(0).limit(items_per_page)
        users.each do |user|
          expect(table).to have_content(user.id)
          expect(table).to have_content(user.login)
          expect(table).to have_content(user.name)
        end
      end

      it "displays enabled pagination controls" do
        visit users_path
        expect(current_path).to eq(users_path)

        controls = find('.pagination_controls')
        expect(controls).to have_content "Displaying items 1-20 of 31"
        # Expect prev navigation to be disabled.
        expect(controls).to have_css('.page.prev.disabled')
        # Expect next navigation to not be disabled.
        expect(controls).not_to have_css('.page.next.disabled')
        expect(controls).to have_css('.page.next')
        expect(controls).to have_css('a[rel="next"]')
      end

      it "allows navigating to the next page" do
        visit users_path
        expect(current_path).to eq(users_path)
        table = find('.resource_table')
        controls = find('.pagination_controls')

        # Users expected to be on second page are not displayed.
        second_page_users = User.all.order(:id).offset(items_per_page).limit(items_per_page)
        second_page_users.each do |user|
          expect(table).not_to have_content(user.login)
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
        second_page_users.each do |user|
          expect(table).to have_content(user.id)
          expect(table).to have_content(user.login)
          expect(table).to have_content(user.name)
        end

        # Expect prev navigation to not be disabled.
        expect(controls).not_to have_css('.page.prev.disabled')
        expect(controls).to have_css('.page.prev')
        expect(controls).to have_css('a[rel="prev"]')
        # Expect next navigation to be disabled.
        expect(controls).to have_css('.page.next.disabled')
      end

      it "allows navigating to the prev page" do
        visit users_path(page: 2)
        expect(current_path).to eq(users_path)
        table = find('.resource_table')
        controls = find('.pagination_controls')

        # Users expected to be on first page are not displayed.
        first_page_users = User.all.order(:id).offset(0).limit(items_per_page)
        first_page_users.each do |user|
          expect(table).not_to have_content(user.login)
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
        first_page_users.each do |user|
          expect(table).to have_content(user.id)
          expect(table).to have_content(user.login)
          expect(table).to have_content(user.name)
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
      create_list(:user, items_per_page)
      create(:user, login: 'aaa', name: 'ZZZ-aaa') # Create a user with an "earlier" login, but "later" name.
      create(:user, login: 'ZZZ', name: 'ZZZ-ZZZ') # Create a user with a "later" login, and name.
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
      #visit users_path
      visit users_path(direction: :asc, sort: :name)
      table = find('.resource_table')

      expect(table).not_to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')

      header = table.find('thead')
      header.click_link "Username"

      table = find('.resource_table')
      expect(table).to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')

      click_link "Next"

      table = find('.resource_table')
      expect(table).not_to have_content('ZZZ-aaa')
      expect(table).not_to have_content('ZZZ-ZZZ')

      click_link "Next"
      table = find('.resource_table')
      expect(table).not_to have_content('ZZZ-aaa')
      expect(table).to have_content('ZZZ-ZZZ')
    end
  end

  describe "searching" do
    before(:each) do
      # Create enough users to fill an entire page.  They will have logins
      # such as `user-1`, `user-2`, etc..
      create_list(:user, items_per_page)
      # Create a couple of users with logins that sort after the earlier
      # users.  They will not be displayed on the initial page load.
      create(:user, login: 'zzz-wanted-1')
      create(:user, login: 'zzz-wanted-2')
    end

    it "allows filtering for users" do
      visit users_path(direction: :asc, sort: :login)
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

    context 'users have teams' do
      let!(:team) { create(:team, name: "Hufflepuff") }
      let!(:team_role) { create(:team_role, team: team) }
      let!(:another_role) { create(:team_role, team: team) }

      it "allows searching for users by team name" do
        visit users_path

        controls = find('.search_controls')
        within(controls) do
          fill_in "Search", with: 'Hufflepuff'
          click_on "Go"
        end

        table = find('.resource_table')
        expect(table.all('tbody tr').count).to eq 2
        expect(table).to have_content(team_role.user.login)
        expect(table).to have_content(another_role.user.login)

        within(controls) do
          fill_in "Search", with: 'Slytherin'
          click_on "Go"
        end

        expect(page).to have_content('No users have been found')
      end
    end
  end
end
