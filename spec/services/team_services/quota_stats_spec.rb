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

RSpec.describe TeamServices::QuotaStats, type: :service do
  let(:team) { create(:team, :with_openstack_details) }
  let(:rack_template) { create(:template, :rack_template) }
  let!(:rack) { create(:rack, team: team, template: rack_template) }
  let(:location) { create(:location, rack: rack) }
  let(:chassis) { create(:chassis, template: template, location: location) }
  let!(:other_team_rack) { create(:rack, template: rack_template) }
  let(:other_team_location) { create(:location, rack: other_team_rack) }
  let(:other_team_chassis) { create(:chassis, template: template, location: other_team_location) }
  let(:quotas) {
    {
      "backup_gigabytes" => 1024,
      "cores" => 21,
      "fixed_ips" => -1,
      "gigabytes" => 2048,
      "id" => "abc",
      "instances" => 10,
      "key_pairs" => 100,
      "network" => 100,
      "ram" => 419200,
      "volumes" => 17
    }
  }
  subject { TeamServices::QuotaStats.call(team, quotas) }

  context 'no records in database' do
    it 'returns counts of zero, for relevant quotas only' do
      expected = {
        total_vcpus: "0 / #{quotas["cores"]}",
        total_disk_space: "0 / #{quotas["gigabytes"]}GB",
        total_ram: "0.0 / #{quotas["ram"] / 1024.0}GB",
        servers: "0 / #{quotas["instances"]}",
        volumes: "0 / #{quotas["volumes"]}",
        networks: "0 / #{quotas["network"]}"
      }
      expect(subject).to eq expected
    end
  end

  context 'has servers' do
    let(:template) { create(:template, :device_template, vcpus: 2, ram: 4096, disk: 10) }
    let!(:server) { create(:instance, status: "STOPPED", chassis: chassis) }
    let!(:another_server) { create(:instance, status: "FAILED", chassis: chassis) }
    let!(:further_server) { create(:instance, status: "ACTIVE", chassis: chassis) }
    let!(:other_team_server) { create(:instance, chassis: other_team_chassis) }

    it 'includes counts, vcpu, ram and disk usage' do
      expected = {
        total_vcpus: "6 / #{quotas["cores"]}",
        total_disk_space: "30 / #{quotas["gigabytes"]}GB",
        total_ram: "12.0 / #{quotas["ram"] / 1024.0}GB",
        servers: "3 / #{quotas["instances"]}",
        volumes: "0 / #{quotas["volumes"]}",
        networks: "0 / #{quotas["network"]}"
      }
      expect(subject).to eq expected
    end

    context 'and volume' do
      let(:another_location) { create(:location, rack: rack) }
      let(:another_chassis) { create(:chassis, template: vol_template, location: location) }
      let(:vol_template) { create(:template, :volume_device_template) }
      let!(:volume) { create(:volume, details: Device::VolumeDetails.new(size: 100), status: "AVAILABLE", chassis: another_chassis) }

      it 'combines server and volume disk space' do
        expected = {
          total_vcpus: "6 / #{quotas["cores"]}",
          total_disk_space: "130 / #{quotas["gigabytes"]}GB",
          total_ram: "12.0 / #{quotas["ram"] / 1024.0}GB",
          servers: "3 / #{quotas["instances"]}",
          volumes: "1 / #{quotas["volumes"]}",
          networks: "0 / #{quotas["network"]}"
        }
        expect(subject).to eq expected
      end
    end
  end

  context 'has volumes' do
    let(:template) { create(:template, :volume_device_template) }
    let!(:volume) { create(:volume, details: Device::VolumeDetails.new(size: 100), status: "AVAILABLE", chassis: chassis) }
    let!(:another_volume) { create(:volume, details: Device::VolumeDetails.new(size: 200), status: "FAILED", chassis: chassis) }
    let!(:further_volume) { create(:volume, details: Device::VolumeDetails.new(size: 10), status: "ACTIVE", chassis: chassis) }
    let!(:other_team_volume) { create(:volume, details: Device::VolumeDetails.new(size: 10), chassis: other_team_chassis) }

    it 'includes counts and disk usage' do
      expected = {
        total_vcpus: "0 / #{quotas["cores"]}",
        total_disk_space: "310 / #{quotas["gigabytes"]}GB",
        total_ram: "0.0 / #{quotas["ram"] / 1024.0}GB",
        servers: "0 / #{quotas["instances"]}",
        volumes: "3 / #{quotas["volumes"]}",
        networks: "0 / #{quotas["network"]}"
      }
      expect(subject).to eq expected
    end
  end

  context 'has networks' do
    let!(:rack_template) { create(:template, :rack_template) }
    let(:template) { create(:template, :network_device_template) }
    let!(:network) { create(:network, details: Device::NetworkDetails.new, status: "STOPPED", chassis: chassis) }
    let!(:another_network) { create(:network, details: Device::NetworkDetails.new, status: "ACTIVE", chassis: chassis) }
    let!(:further_network) { create(:network, details: Device::NetworkDetails.new, status: "ACTIVE", chassis: chassis) }
    let!(:other_team_network) { create(:network, details: Device::NetworkDetails.new, status: "ACTIVE", chassis: other_team_chassis) }

    it 'includes network count' do
      expected = {
        total_vcpus: "0 / #{quotas["cores"]}",
        total_disk_space: "0 / #{quotas["gigabytes"]}GB",
        total_ram: "0.0 / #{quotas["ram"] / 1024.0}GB",
        servers: "0 / #{quotas["instances"]}",
        volumes: "0 / #{quotas["volumes"]}",
        networks: "3 / #{quotas["network"]}"
      }
      expect(subject).to eq expected
    end
  end
end
