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

RSpec.describe Device::NetworkDetails, type: :model do
  let(:team) { create(:team) }
  let!(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, team: team, template: rack_template) }
  let(:location) { create(:location, rack: rack) }
  let(:chassis) { create(:chassis, location: location, template: template) }

  let(:device_template) { create(:template, :device_template) }
  let(:network_template) { create(:template, :network_device_template) }

  let(:device) { create(:device, chassis: chassis, details: described_class.new) }

  subject { device.details }

  describe 'validations' do
    context 'for a device using the network template' do
      let(:template) { network_template }

      it { is_expected.to be_valid }
    end

    context 'for a device using the compute device template' do
      let(:template) { device_template }

      it { is_expected.not_to be_valid }
      it { is_expected.to have_error :device, 'must use the `network` template if it has a Device::NetworkDetails' }

      it 'also shows error on device' do
        expect(device).not_to be_valid
        expect(device).to have_error :details, 'is invalid'
      end
    end

  end
end
