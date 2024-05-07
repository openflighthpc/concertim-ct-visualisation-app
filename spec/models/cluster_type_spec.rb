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

RSpec.describe ClusterType, type: :model do
  subject { create(:cluster_type) }
  let(:fields) do
    { "clustername"=>
      {
        "type"=>"string",
        "label"=>"Cluster name",
        "order"=>0,
        "constraints"=>
      [
        {
          "length"=>{"max"=>255, "min"=>6},
          "description"=>"Cluster name must be between 6 and 255 characters"
        },
        {
          "description"=>
        "Cluster name can contain only alphanumeric characters, hyphens and underscores",
          "allowed_pattern"=>"^[a-zA-Z][a-zA-Z0-9\\-_]*$"
        }
      ],
        "description"=>"The name to give the cluster"
      }
    }
  end

  describe 'validations' do
    it "is valid with valid attributes" do
      cluster_type = described_class.new(
        name: 'Test cluster',
        description: 'A test cluster type.  It exists only for test purposes.',
        foreign_id: 'test-cluster',
        fields: fields,
        version: Time.current
      )
      expect(cluster_type).to be_valid
    end

    it "has a valid factor" do
      cluster_type = described_class.new(attributes_for(:cluster_type))
      expect(cluster_type).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to have_error(:name, :blank)
    end

    it "is not valid without a description" do
      subject.description = nil
      expect(subject).to have_error(:description, :blank)
    end

    describe "foreign id" do
      it "is not valid without a foreign id" do
        subject.foreign_id = nil
        expect(subject).to have_error(:foreign_id, :blank)
      end

      it "must have a unique foreign_id" do
        new_cluster_type = build(:cluster_type, foreign_id: subject.foreign_id)
        expect(new_cluster_type).to have_error(:foreign_id, :taken)
      end
    end
  end
end
