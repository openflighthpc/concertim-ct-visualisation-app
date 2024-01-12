class TeamPresenter < Presenter
  include Costed

  def status
    if o.deleted_at.nil?
      "Active"
    else
      "Pending deletion"
    end
  end

  def delete_confirmation_message
    "Are you sure you want to delete team #{o.name}?" \
    " This will delete all of their racks and devices."
  end

  def billing_period
    return "pending (awaiting update)" unless o.billing_period_start && o.billing_period_end

    "#{o.billing_period_start.strftime("%Y/%m/%d")} - #{o.billing_period_end.strftime("%Y/%m/%d")}"
  end

  def team_users_list(role)
    o.team_roles.where(role: role).map {|team_role| team_role.user.name }.join(", ")
  end

  def formatted_credits
    '%.2f' % o.credits
  end

  def project_id_form_hint
    form_hint(:project_id)
  end

  def billing_acct_id_form_hint
    form_hint(:billing_acct_id)
  end

  private

  def form_hint(attribute)
    if o.send(attribute).blank?
      I18n.t("simple_form.customisations.hints.team.edit.#{attribute}.blank")
    else
      I18n.t("simple_form.customisations.hints.team.edit.#{attribute}.present")
    end
  end
end
