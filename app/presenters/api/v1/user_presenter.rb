#
# Api::V1::UserPresenter
#
# User Presenter for the API
module Api::V1
  class UserPresenter < Presenter

    # Be selective about what attributes and methods we expose.
    delegate :id, :login, :name, :email, :cloud_user_id, :root?, :team_roles,
             to: :o

    def status
      if o.deleted_at.nil?
        "active"
      else
        "pending deletion"
      end
    end
  end
end
