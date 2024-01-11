class TeamPresenter < Presenter
  include Costed

  def billing_period
    return "pending (awaiting update)" unless o.billing_period_start && o.billing_period_end

    "#{o.billing_period_start.strftime("%Y/%m/%d")} - #{o.billing_period_end.strftime("%Y/%m/%d")}"
  end

  def team_role_list
    o.team_roles.map {|team_role| "#{team_role.user.login} (#{team_role.role})" }.sort.join(", ")
  end

  # def formatted_credits
  #   '%.2f' % o.credits
  # end
end
