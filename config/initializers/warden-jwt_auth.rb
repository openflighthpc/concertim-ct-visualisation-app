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

module Users
  module WardenJWTAuth
    module TokenEncoder
      # warden-jwt_auth will happily allow claims with a `null` value.  For the
      # `aud` key, this breaks verifying the token for some libraries.  Those
      # libraries assume that a `null` audience means the token has an audience
      # specified as no audience. Whereas an `undefined` (or absent) audience
      # means that the audience is unspecified.  I'm not sure that that is
      # wrong behaviour.  Either way, we fix the issue by removing all `null`
      # claims.   Perhaps this should be limited to just removing `null` `aud`
      # claims instead.
      module NullClaimsFix
        private

        def merge_with_default_claims(payload)
          super.compact
        end
      end
    end
  end
end

Warden::JWTAuth::TokenEncoder.prepend(Users::WardenJWTAuth::TokenEncoder::NullClaimsFix)
