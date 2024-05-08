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

RSpec.describe "non-admin user editing their own account", type: :system do
  let(:initial_password) { 'user-password' }
  let!(:user) { create(:user, password: initial_password) }

  def sign_in(username:, password:)
    visit new_user_session_path
    expect(current_path).to eq(new_user_session_path)
    fill_in "Username", with: username
    fill_in "Password", with: password
    click_on "Login"
  end

  before(:each) do
    sign_in(username: user.login, password: initial_password)
  end

  describe "form elements" do
    it "contains expected fields" do
      visit edit_user_registration_path(user)
      form = find("form[id='edit_user']")
      expect(form).to have_field("Name", with: user.name)
      expect(form).to have_field("New password")
      expect(form).to have_field("Password confirmation")
      expect(form).to have_field("Current password")
      expect(form.find_field("New password").text).to be_blank
      expect(form.find_field("Password confirmation").text).to be_blank
      expect(form.find_field("Current password").text).to be_blank
    end
  end

  describe "changing password" do
    context "with valid values" do
      let(:new_password) { 'new-user-password' }

      it "updates the expected fields" do
        visit edit_user_registration_path(user)
        form = find("form[id='edit_user']")
        form.fill_in "New password", with: new_password
        form.fill_in "Password confirmation", with: new_password
        form.fill_in "Current password", with: initial_password
        form.click_on "Update"

        expect(page).to have_text "Your account has been updated successfully"

        # Sign out and check we can sign back in with the new credentials, but
        # not the old.
        visit destroy_user_session_path
        sign_in(username: user.login, password: initial_password)
        expect(page).to have_text "Invalid username or password"
        sign_in(username: user.login, password: new_password)
        expect(page).to have_text "Signed in successfully"
      end
    end

    context "with invalid values" do
      it "displays the errors and keeps the user's input" do
        visit edit_user_registration_path(user)
        form = find("form[id='edit_user']")
        form.fill_in "New password", with: "new-password"
        form.fill_in "Password confirmation", with: "NEW-PASSWORD"
        form.fill_in "Current password", with: initial_password
        form.click_on "Update"

        expect(page).to have_text "prohibited this user from being saved"
        expect(page).to have_text "Password confirmation doesn't match Password"
      end
    end
  end
end

