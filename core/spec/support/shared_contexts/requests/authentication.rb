require 'devise/jwt/test_helpers'

RSpec.shared_context "Not logged in" do
  let(:headers) { {} }
end

RSpec.shared_context "Logged in as admin" do
  let(:headers) { Devise::JWT::TestHelpers.auth_headers({}, authenticated_user) }
  let(:authenticated_user) { create(:user, :admin) }
end

RSpec.shared_context "Logged in as non-admin" do
  let(:headers) { Devise::JWT::TestHelpers.auth_headers({}, authenticated_user) }
  let(:authenticated_user) { create(:user) }
end
