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

RSpec.describe Cluster, type: :model do
  let(:cluster_params) { { "clustername" => "testing"} }
  subject { build(:cluster, cluster_params: cluster_params) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without a name" do
    subject.name = nil
    expect(subject).to have_error(:name, :blank)
  end

  it "is not valid without a cluster type" do
    subject.cluster_type = nil
    expect(subject).to have_error(:cluster_type, :blank)
  end

  it "is not valid with a blank param" do
    cluster_params["clustername"] = nil
    expect(subject).to have_error("Cluster name", "can't be blank")
  end

  it "is not valid without a team" do
    subject.team = nil
    expect(subject).to have_error(:team, :blank)
  end

  it "is not valid if team has insufficient credits" do
    subject.team.update(credits: 0)
    expect(subject).to have_error(:team, "Has insufficient credits to launch a cluster")
  end
end
