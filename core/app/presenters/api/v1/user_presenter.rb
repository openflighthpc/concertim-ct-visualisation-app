#
# Api::V1::UserPresenter
#
# User Presenter for the API
module Api::V1
  class UserPresenter < Emma::Presenter
    include Emma::Costed

    # Be selective about what attributes and methods we expose.
    delegate :id, :login, :name, :cloud_user_id, :project_id, :root?,
             :cost,:billing_period_start, :billing_period_end,
             to: :o

  end
end
