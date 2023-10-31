require 'rails_helper'

RSpec.describe CloudServiceConfig, type: :model do
  subject { create(:cloud_service_config) }

  describe 'validations' do
    it "is valid with valid attributes" do
      config = described_class.new(
        internal_auth_url: "https://example.com",
        admin_user_id: 'admin',
        admin_foreign_password: 'REDACTED',
        user_handler_base_url: 'http://testing.com:1234',
        cluster_builder_base_url: 'http://testing.com:5678',
        admin_project_id: 'my-project-id'
      )
      expect(config).to be_valid
    end

    describe "internal_auth_url" do
      it "is not valid without an internal_auth_url" do
        subject.internal_auth_url = nil
        expect(subject).to have_error(:internal_auth_url, :blank)
      end

      it "is not valid with a badly formatted internal_auth_url" do
        subject.internal_auth_url = "not a url"
        expect(subject).to have_error(:internal_auth_url, :invalid)
      end
    end

    it "is not valid without an admin user id" do
      subject.admin_user_id = nil
      expect(subject).to have_error(:admin_user_id, :blank)
    end

    it "is not valid without an admin password" do
      subject.admin_foreign_password = nil
      expect(subject).to have_error(:admin_foreign_password, :blank)
    end

    %w(user_handler_base_url cluster_builder_base_url).each do |base_url|
      describe base_url do
        it "is not valid without a #{base_url}" do
          subject.send("#{base_url}=", nil)
          expect(subject).to have_error(base_url, :blank)
        end

        it "is not valid with a badly formatted #{base_url}" do
          subject.send("#{base_url}=", "not a url")
          expect(subject).to have_error(base_url, :invalid)
        end
      end
    end

    it "is not valid without an admin project_id" do
      subject.admin_project_id = nil
      expect(subject).to have_error(:admin_project_id, :blank)
    end
  end
end
