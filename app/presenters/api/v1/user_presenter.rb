#
# Api::V1::UserPresenter
#
# User Presenter for the API
module Api::V1
  class UserPresenter < Presenter
    include Costed

    # Be selective about what attributes and methods we expose.
    delegate :id, :login, :name, :email, :cloud_user_id, :project_id, :root?,
             :billing_period_start, :billing_period_end, :billing_acct_id,
             to: :o

  end
end
