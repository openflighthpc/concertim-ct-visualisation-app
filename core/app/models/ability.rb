class Ability
  include Emma::Ability::Common
  
  ################################################
  #
  # ACCESS CONTROL PERMISSIONS
  #
  # Things all access controlled users should be able to do.
  #
  def access_control_permissions!(user)
    super
    # can :edit, :overview
  end


  ################################################
  #
  # IMPORTANT PROHIBITIONS
  #
  # Things no user should ever be able to do.
  #
  def important_prohibitions!(user)
    super
  end
end
