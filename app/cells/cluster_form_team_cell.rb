class ClusterFormTeamCell < Cell::ViewModel
  def show(cluster, form, user)
    @record = cluster
    @form = form
    @user = user
    @errors = @record.errors
    @attribute = :team_id
    render
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

  def f
    @form
  end

  def attribute
    @attribute
  end

  def has_errors?
    @errors.include?(@attribute)
  end

  def label_classes
    "required_field".tap do |classes|
      classes << " label_with_errors" if has_errors?
    end
  end

  def

  def error_message
    @errors.messages_for(@attribute).to_sentence
  end
end
