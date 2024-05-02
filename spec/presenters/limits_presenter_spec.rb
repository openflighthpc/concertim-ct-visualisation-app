require 'rails_helper'

RSpec.describe LimitsPresenter, type: :model do
  let(:presenter) { LimitsPresenter.new(limits) }

  describe 'grouped limits' do
    let(:limits) do
      {
        "maxImageMeta" =>128,
        "maxPersonality" =>5,
        "maxPersonalitySize" =>10240,
        "maxSecurityGroupRules" =>-1,
        "maxSecurityGroups" =>-1,
        "maxServerGroupMembers" =>10,
        "maxServerGroups" =>10,
        "maxServerMeta" =>128,
        "maxTotalBackupGigabytes" =>1024,
        "maxTotalBackups" =>10,
        "maxTotalCores" =>22,
        "maxTotalFloatingIps" =>-1,
        "maxTotalInstances" =>10,
        "maxTotalKeypairs" =>100,
        "maxTotalRAMSize" =>10240,
        "maxTotalSnapshots" =>10,
        "maxTotalVolumeGigabytes" =>2048,
        "maxTotalVolumes" =>20,
        "totalBackupGigabytesUsed" =>0,
        "totalBackupsUsed" =>0,
        "totalCoresUsed" =>13,
        "totalFloatingIpsUsed" =>0,
        "totalGigabytesUsed" =>1136,
        "totalInstancesUsed" =>7,
        "totalRAMUsed" =>1024,
        "totalSecurityGroupsUsed" =>0,
        "totalServerGroupsUsed" =>0,
        "totalSnapshotsUsed" =>0,
        "totalVolumesUsed" =>8
      }
    end
    subject { presenter.grouped_limits }

    context 'relevant aspects have limits' do

      it 'matches usage against limits' do
        expected = {
          total_vcpus: "13 / 22",
          total_disk_space: "1136 / 2048GB",
          total_ram: "1.0 / 10.0GB",
          servers: "7 / 10",
          volumes: "8 / 20"
        }
        expect(subject).to eq expected
      end
    end

    context 'no limit for usage without units' do
      it 'replaces -1 with no limit' do
        limits["maxTotalVolumes"] = -1
        expect(subject[:volumes]).to eq "8 / No limit"
      end
    end

    context 'no limit for disk space' do
      it 'replaces -1 with no limit and puts unit in right place' do
        limits["maxTotalVolumeGigabytes"] = -1
        expect(subject[:total_disk_space]).to eq "1136GB / No limit"
      end
    end

    context 'no limit for ram' do
      it 'replaces -1 with no limit and puts unit in right place' do
        limits["maxTotalRAMSize"] = -1
        expect(subject[:total_ram]).to eq "1.0GB / No limit"
      end
    end
  end
end
