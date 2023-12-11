class UserPresenter < Presenter
  include Costed

  def billing_period
    return "pending (awaiting update)" unless o.billing_period_start && o.billing_period_end

    "#{o.billing_period_start.strftime("%Y/%m/%d")} - #{o.billing_period_end.strftime("%Y/%m/%d")}"
  end

  def authorization
    if o.root?
      "Administrator"
    else
      "User"
    end
  end
end
