module Uma
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

Warden::JWTAuth::TokenEncoder.prepend(Uma::WardenJWTAuth::TokenEncoder::NullClaimsFix)
