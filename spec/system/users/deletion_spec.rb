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

RSpec.describe "user deletion", type: :system do
  include ActiveJob::TestHelper

  before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  let(:admin_password) { 'admin-password' }
  let!(:admin) { create(:user, :admin, password: admin_password) }
  let!(:user_to_delete) { create(:user) }
  let!(:some_other_user) { create(:user) }
  let!(:cloud_config) { create(:cloud_service_config) }

  before(:each) do
    visit new_user_session_path
    expect(current_path).to eq(new_user_session_path)
    fill_in "Username", with: admin.login
    fill_in "Password", with: admin_password
    click_on "Login"
  end

  describe "workflows" do
    specify "user can be scheduled for deletion" do
      visit users_path
      table = find('.resource_table')
      user_row = table.find("tr[data-test='user-#{user_to_delete.id}']")
      expect(user_row).to have_text 'Active'

      user_row.click_on "Actions"
      user_row.click_on "Delete"

      expect(page).to have_text 'Scheduled user for deletion'
      table = find('.resource_table')
      user_row = table.find("tr[data-test='user-#{user_to_delete.id}']")
      expect(user_row).to have_text 'Pending deletion'

      expect(UserDeletionJob).to have_been_enqueued.exactly(:once).with(user_to_delete, cloud_config)
    end

    specify "deleting a user doesn't delete other users" do
      visit users_path
      table = find('.resource_table')
      user_row = table.find("tr[data-test='user-#{user_to_delete.id}']")
      expect(user_row).to have_text 'Active'

      user_row.click_on "Actions"
      user_row.click_on "Delete"

      expect(page).to have_text 'Scheduled user for deletion'
      table = find('.resource_table')
      other_user_row = table.find("tr[data-test='user-#{some_other_user.id}']")
      expect(other_user_row).to have_text 'Active'

      expect(UserDeletionJob).to have_been_enqueued.exactly(:once)
      expect(UserDeletionJob).not_to have_been_enqueued.with(some_other_user, cloud_config)
    end

    # XXX Enable this when I can get selenium working inside of a docker
    # container.  We need a browser test for dismiss_confirm.
    xspecify "user deletion requires confirmation", js: true do
      visit users_path
      table = find('.resource_table')
      user_row = table.find("tr[data-test='user-#{user_to_delete.id}']")
      expect(user_row).to have_text 'Active'

      user_row.click_on "Actions"
      dismiss_confirm do
        user_row.click_on "Delete"
      end

      expect(page).not_to have_text 'Scheduled user for deletion'
      table = find('.resource_table')
      user_row = table.find("tr[data-test='user-#{user_to_delete.id}']")
      expect(user_row).to have_text 'Active'

      expect(UserDeletionJob).not_to have_been_enqueued
    end
  end
end
