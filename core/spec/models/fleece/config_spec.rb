require 'rails_helper'

RSpec.describe Fleece::Config, type: :model do
  subject { create(:fleece_config) }

  describe 'validations' do
    it "is valid with valid attributes" do
      config = described_class.new(
        host_url: "http://testing.com",
        internal_auth_url: "https://example.com",
        admin_user_id: 'admin',
        admin_openstack_password: 'REDACTED',
        user_handler_port: '1234',
        cluster_builder_port: '5678',
        admin_project_id: 'my-project-id'
      )
      expect(config).to be_valid
    end

    describe "host_url" do
      it "is not valid without a host_url" do
        subject.host_url = nil
        expect(subject).to have_error(:host_url, :blank)
      end

      it "is not valid with a badly formatted host_url" do
        subject.host_url = "not a url"
        expect(subject).to have_error(:host_url, :invalid)
      end
    end

    describe "internal_auth_url" do
      it "is not valid without an internal_auth_url" do
        subject.internal_auth_url = nil
        expect(subject).to have_error(:internal_auth_url, :blank)
      end

      it "is not valid with a badly formatted host_url" do
        subject.internal_auth_url = "not a url"
        expect(subject).to have_error(:internal_auth_url, :invalid)
      end
    end

    it "is not valid without an admin user id" do
      subject.admin_user_id = nil
      expect(subject).to have_error(:admin_user_id, :blank)
    end

    it "is not valid without an admin password" do
      subject.admin_openstack_password = nil
      expect(subject).to have_error(:admin_openstack_password, :blank)
    end

    %w(user_handler_port cluster_builder_port).each do |port|
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

    it "is not valid without an admin project_id" do
      subject.admin_project_id = nil
      expect(subject).to have_error(:admin_project_id, :blank)
    end
  end

  describe "user_handler_base_url" do
    it "is as expected" do
      expected_url = "#{subject.host_url[0...-5]}:#{subject.user_handler_port}"
      expect(subject.user_handler_base_url).to eq expected_url
    end
  end

  describe "cluster_builder_url" do
    it "is as expected" do
      expected_url = "#{subject.host_url[0...-5]}:#{subject.cluster_builder_port}"
      expect(subject.cluster_builder_base_url).to eq expected_url
    end
  end
end
