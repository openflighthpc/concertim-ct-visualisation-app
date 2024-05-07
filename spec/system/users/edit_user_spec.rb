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

RSpec.describe "admin user editing other users", type: :system do
  let(:admin_password) { 'admin-password' }
  let!(:admin) { create(:user, :admin, password: admin_password) }

  before(:each) do
    visit new_user_session_path
    expect(current_path).to eq(new_user_session_path)
    fill_in "Username", with: admin.login
    fill_in "Password", with: admin_password
    click_on "Login"
  end

  describe "form elements" do
    context "when user does not have a cloud ID" do
      let(:user) { create(:user) }

      it "contains expected fields" do
        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        expect(form).to have_field("Name", with: user.name)
        expect(form).to have_field("Cloud User ID")
        expect(form.find_field("Cloud User ID").text).to be_blank
      end

      it "contains the expected hint" do
        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        field = form.find_field("Cloud User ID")
        expect(field).to have_sibling(".hint")
        expect(field.sibling(".hint")).to have_text(/cloud user ID will be updated automatically/)
      end
    end

    context "when user has a cloud ID" do
      let(:user) { create(:user, :with_openstack_account) }

      it "contains expected fields" do
        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        expect(form).to have_field("Name", with: user.name)
        expect(form).to have_field("Cloud User ID", with: user.cloud_user_id)
      end

      it "contains the expected hint" do
        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        field = form.find_field("Cloud User ID")
        expect(field).to have_sibling(".hint")
        expect(field.sibling(".hint")).to have_text(/Changing the user's cloud user ID/)
      end
    end
  end

  describe "form submission" do
    let(:user) { create(:user) }

    context "with valid values" do
      it "updates the expected fields" do
        expect(user.cloud_user_id).to be_nil

        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        form.fill_in "Cloud User ID", with: "my new cloud user id"
        form.click_on "Update User"

        expect(page).to have_text "Successfully updated user"
        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        expect(form).to have_field("Cloud User ID", with: "my new cloud user id")
      end
    end

    context "with invalid values" do
      it "displays the errors and keeps the user's input" do
        expect(user.cloud_user_id).to be_nil

        visit edit_user_path(user)
        form = find("form[id='edit_user_#{user.id}']")
        form.fill_in "Name", with: ""
        form.fill_in "Cloud User ID", with: "my new project id"
        form.click_on "Update User"

        expect(page).to have_text "Unable to update user"
        form = find("form[id='edit_user_#{user.id}']")
        expect(form).to have_field("Name", with: "")
        expect(form.find_field("Name")).to have_sibling(".error", text: "can't be blank")
        expect(form).to have_field("Cloud User ID", with: "my new project id")
      end
    end
  end
end
