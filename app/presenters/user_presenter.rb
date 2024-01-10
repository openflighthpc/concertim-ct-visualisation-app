class UserPresenter < Presenter

  def authorization
    if o.root?
      "Super Admin"
    else
      "User"
    end
  end

  def status
    if o.deleted_at.nil?
      "Active"
    else
      "Pending deletion"
    end
  end

  def delete_confirmation_message
    "Are you sure you want to delete user #{o.name} (#{o.login})?" \
      " This will delete all of their racks and devices."
  end

  def team_role_list
    o.team_roles.map {|team_role| "#{team_role.team.name} (#{team_role.role})" }.sort.join(", ")
  end

  def cloud_user_id_form_hint
    form_hint(:cloud_user_id)
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
