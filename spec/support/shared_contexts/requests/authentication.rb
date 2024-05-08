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

require 'devise/jwt/test_helpers'

RSpec.shared_context "Not logged in" do
  let(:headers) { {} }
  let(:authenticated_user) { nil }
end

RSpec.shared_context "Logged in as admin" do
  let(:headers) { Devise::JWT::TestHelpers.auth_headers({}, authenticated_user) }
  let(:authenticated_user) { create(:user, :admin) }
end

RSpec.shared_context "Logged in as non-admin" do
  let(:headers) { Devise::JWT::TestHelpers.auth_headers({}, authenticated_user) }
  let(:authenticated_user) { create(:user) }
end
