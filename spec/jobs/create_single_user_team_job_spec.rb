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

RSpec.describe CreateSingleUserTeamJob, type: :job do
  include ActiveJob::TestHelper
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let!(:user) { create(:user, :with_openstack_account, login: "bilbo") }
  let(:changes) { {} }
  let(:cloud_service_config) { create(:cloud_service_config) }

  subject(:job) {
    CreateSingleUserTeamJob.perform_now(user, cloud_service_config)
  }

  before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "creates a single user team with the user's username" do
    expect { subject }.to change(Team, :count).by(1)
    team = Team.last
    expect(team.name).to eq "bilbo_team"
    expect(team.single_user).to eq true
  end

  it "assigns user as team admin" do
    expect { subject }.to change(TeamRole, :count).by(1)
    role = TeamRole.last
    team = Team.last
    expect(role.user).to eq user
    expect(role.team).to eq team
    expect(role.role).to eq 'admin'
  end

  it "rolls back creation of team if user assignment fails" do
    user.root = true
    expect { subject rescue nil }.to not_change(Team, :count).and not_change(TeamRole, :count)

    expect(CreateTeamThenRoleJob).not_to have_been_enqueued
  end

  it "enqueues creation of a team in openstack" do
    subject
    expect(CreateTeamThenRoleJob).to have_been_enqueued.with(Team.last, TeamRole.last, cloud_service_config)
  end

  it "does not enqueue creation of team in openstack if unsuccessful" do
    create(:team, name: "bilbo_team")
    expect { subject rescue nil }.not_to change(Team, :count)
    expect(CreateTeamThenRoleJob).not_to have_been_enqueued
  end

end
