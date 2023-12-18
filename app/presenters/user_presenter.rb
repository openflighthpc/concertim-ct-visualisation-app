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

  def formatted_credits
    '%.2f' % o.credits
  end

  def cloud_user_id_form_hint
    form_hint(:cloud_user_id)
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
      I18n.t("simple_form.customisations.hints.user.edit.#{attribute}.blank")
    else
      I18n.t("simple_form.customisations.hints.user.edit.#{attribute}.present")
    end
  end
end
