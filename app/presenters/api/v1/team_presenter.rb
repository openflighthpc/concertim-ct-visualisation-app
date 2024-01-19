#
# Api::V1::UserPresenter
#
# Team Presenter for the API
module Api::V1
  class TeamPresenter < Presenter

    # Be selective about what attributes and methods we expose.
    delegate :id, :name, :project_id, :billing_acct_id, :billing_period_start, :billing_period_end, :cost,
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
