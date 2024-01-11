class TeamPresenter < Presenter
  include Costed

  def billing_period
    return "pending (awaiting update)" unless o.billing_period_start && o.billing_period_end

    "#{o.billing_period_start.strftime("%Y/%m/%d")} - #{o.billing_period_end.strftime("%Y/%m/%d")}"
  end

  def team_users_list(role)
    o.team_roles.where(role: role).map {|team_role| team_role.user.name }.join(", ")
  end

  # def formatted_credits
  #   '%.2f' % o.credits
  # end
end
