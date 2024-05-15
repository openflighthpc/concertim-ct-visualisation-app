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

RSpec.describe Device::VolumeDetails, type: :model do
  let(:team) { create(:team) }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, team: team, template: rack_template) }
  let(:location) { create(:location, rack: rack) }
  let(:chassis) { create(:chassis, location: location, template: volume_template) }
  let(:volume_template) { create(:template, :volume_device_template) }

  let(:device) { create(:volume, chassis: chassis, details: described_class.new) }

  subject { device.details }

  describe 'validations' do
    context 'for a volume device' do
      it { is_expected.to be_valid }

      it 'is invalid if device is not a volume' do
        device.update(type: "Instance")
        expect(subject).to have_error(:device, "must be a Volume")
      end
    end
  end
end
