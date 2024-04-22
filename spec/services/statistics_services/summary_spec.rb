require 'rails_helper'

RSpec.describe StatisticsServices::Summary, type: :service do
  subject { StatisticsServices::Summary.call }

  context 'no records in database' do
    it 'returns counts of zero' do
      expected = {
        teams: { active: 0 },
        racks: { active: 0, inactive: 0},
        servers: { active: 0, inactive: 0, total_vcpus: 0, total_ram: "0.0GB", total_disk_space: "0GB" },
        volumes: { active: 0, inactive: 0, total_disk_space: "0GB" },
        networks: { active: 0, inactive: 0 }
      }
      expect(subject).to eq expected
    end
  end

  context "has teams" do
    let!(:team) { create(:team) }
    let!(:another_team) { create(:team) }

    it 'includes team count' do
      expect(subject[:teams]).to eq({active: 2})
    end
  end

  context "has racks" do
    let!(:template) { create(:template, :rack_template) }
    let!(:rack) { create(:rack, status: "FAILED", template: template) }
    let!(:another_rack) { create(:rack, status: "ACTIVE", template: template) }

    it 'includes rack counts' do
      expect(subject[:racks]).to eq({active: 1, inactive: 1})
    end
  end

  context 'has servers' do
    let!(:rack_template) { create(:template, :rack_template) }
    let(:template) { create(:template, :device_template, vcpus: 2, ram: 4096, disk: 10) }
    let(:chassis) { create(:chassis, template: template) }
    let!(:server) { create(:device, status: "STOPPED", chassis: chassis) }
    let!(:another_server) { create(:device, status: "FAILED", chassis: chassis) }
    let!(:further_server) { create(:device, status: "ACTIVE", chassis: chassis) }

    it 'includes counts, vcpu, ram and disk usage' do
      expected = {
        active: 1,
        inactive: 2,
        total_vcpus: 6,
        total_ram: "12.0GB",
        total_disk_space: "30GB"
      }
      expect(subject[:servers]).to eq expected
    end
  end

  context 'has volumes' do
    let!(:rack_template) { create(:template, :rack_template) }
    let(:template) { create(:template, :volume_device_template) }
    let(:chassis) { create(:chassis, template: template) }
    let!(:volume) { create(:device, details: Device::VolumeDetails.new(size: 100), status: "STOPPED", chassis: chassis) }
    let!(:another_volume) { create(:device, details: Device::VolumeDetails.new(size: 200), status: "FAILED", chassis: chassis) }
    let!(:further_volume) { create(:device, details: Device::VolumeDetails.new(size: 10), status: "ACTIVE", chassis: chassis) }

    it 'includes counts and disk usage' do
      expected = {
        active: 1,
        inactive: 2,
        total_disk_space: "310GB"
      }
      expect(subject[:volumes]).to eq expected
    end
  end

  context 'has networks' do
    let!(:rack_template) { create(:template, :rack_template) }
    let(:template) { create(:template, :network_device_template) }
    let(:chassis) { create(:chassis, template: template) }
    let!(:network) { create(:device, details: Device::NetworkDetails.new, status: "STOPPED", chassis: chassis) }
    let!(:another_network) { create(:device, details: Device::NetworkDetails.new, status: "ACTIVE", chassis: chassis) }
    let!(:further_network) { create(:device, details: Device::NetworkDetails.new, status: "ACTIVE", chassis: chassis) }

    it 'includes network counts' do
      expect(subject[:networks]).to eq({active: 2, inactive: 1})
    end
  end
end
