class TeamRolePresenter < Presenter
  delegate :id, :role, :team_id, :user_id, to: :o

  def requires_confirmation?(current_user)
    role == "admin" && (own_role(current_user) || only_admin?)
  end

  def own_role(current_user)
    current_user == o.user
  end

  def only_admin?
    @only_admin ||= TeamRole.where(team_id: team_id, role: "admin").where.not(id: id).empty?
  end

  def delete_confirmation(current_user)
    message = ""
    if only_admin?
      message = "This is the only admin user for the team. Removing them will limit access to the team.\n\n"
    end
    if own_role(current_user)
      message << "This will remove your personal access to the team.\n\n"
    end
    message << "Do you wish to continue?"
  end

  def edit_confirmation(current_user)
    message = ""
    if only_admin?
      message = "This is the only admin user for the team. Changing their role will limit access to the team.\n\n"
    end
    if own_role(current_user)
      message << "This will change your personal access to the team.\n\n"
    end
    message << "Do you wish to continue?"
  end
end
