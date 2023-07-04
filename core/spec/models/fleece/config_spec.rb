require 'rails_helper'

RSpec.describe Fleece::Config, type: :model do
  subject { create(:fleece_config) }

  describe 'validations' do
    it "is valid with valid attributes" do
      config = described_class.new(
        host_name: 'hostname',
        host_ip: '8.8.8.8',
        username: 'username',
        password: 'REDACTED',
        port: 443,
        project_name: 'my-project-name',
        domain_name: 'my-project-name',
      )
      expect(config).to be_valid
    end

    describe "host_name" do
      it "is not valid without a host_name" do
        subject.host_name = nil
        expect(subject).to have_error(:host_name, :blank)
      end

      it "is not valid with a badly formatted host_name" do
        subject.host_name = "spaces are not valid"
        expect(subject).to have_error(:host_name, :invalid)
      end
    end

    describe "domain_name" do
      it "is not valid without a domain_name" do
        subject.domain_name = nil
        expect(subject).to have_error(:domain_name, :blank)
      end

      it "is not valid with a badly formatted domain_name" do
        subject.domain_name = "spaces are not valid"
        expect(subject).to have_error(:domain_name, :invalid)
      end
    end

    describe "host_ip" do
      it "is not valid without a host_ip" do
        subject.host_ip = nil
        expect(subject).to have_error(:host_ip, :blank)
      end

      it "is valid with an IPv4 IP" do
        subject.host_ip = "8.8.8.8"
        expect(subject).not_to have_error(:host_ip)
      end

      it "is valid with an IPv6 IP" do
        subject.host_ip = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
        expect(subject).not_to have_error(:host_ip)
      end

      it "is not valid with junk value" do
        subject.host_ip = "not.a.valid.ip"
        expect(subject).to have_error(:host_ip, :blank)
      end
    end

    it "is not valid without a username" do
      subject.username = nil
      expect(subject).to have_error(:username, :blank)
    end

    it "is not valid without a password" do
      subject.password = nil
      expect(subject).to have_error(:password, :blank)
    end

    %w(port user_handler_port).each do |port|
      describe port do
        it "is not valid without a #{port}" do
          subject.send("#{port}=", nil)
          expect(subject).to have_error(port, :not_a_number)
        end

        it "is not valid with a #{port} below 1" do
          subject.send("#{port}=", 0)
          expect(subject).to have_error(port, :greater_than_or_equal_to)
        end

        it "is not valid with a #{port} above 65535" do
          subject.send("#{port}=", 65536)
          expect(subject).to have_error(port, :less_than_or_equal_to)
        end

        it "is not valid with a non-integer #{port}" do
          subject.send("#{port}=", 1.5)
          expect(subject).to have_error(port, :not_an_integer)
        end
      end
    end

    it "is not valid without a project_name" do
      subject.project_name = nil
      expect(subject).to have_error(:project_name, :blank)
    end
  end

  describe "auth_url" do
    it "is as expected" do
      expect(subject.auth_url).to eq "http://#{subject.host_ip}:#{subject.port}/v3"
    end
  end

  describe "user_handler_url" do
    it "is as expected" do
      expected_url = "http://#{subject.host_ip}:#{subject.user_handler_port}/create-user-project/"
      expect(subject.user_handler_url).to eq expected_url
    end
  end
end
