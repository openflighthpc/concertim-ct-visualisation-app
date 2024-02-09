class ClusterFormTeamCell < ClusterFormInputCell
  def show(cluster, form, user)
    @user = user
    @attribute = :team_id
    super(cluster, form)
  end

  private

  def all_teams
    @user.teams
  end

  def valid_teams
    @user.teams.meets_cluster_credit_requirement
  end

  def excluded_teams
    @user.teams.where.not(id: valid_teams.pluck(:id))
  end

  def label_text
    'Team'
  end

  def constraint_text
    "Must have at least #{Rails.application.config.cluster_credit_requirement} credits"
  end
end
