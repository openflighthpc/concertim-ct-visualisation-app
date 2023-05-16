class Ability
  include CanCan::Ability

  def initialize(user)
    enable_abilities(user || User.new)
  end

  private

  def enable_abilities(user)
    if user.root?
      root_abilities(user)
    else
      non_root_abilities(user)
    end

    important_prohibitions(user)
  end

  # Abilities for root users (can essentially do anything).
  def root_abilities(user)
    can :manage, :all
  end

  # Abilities for non-root users.
  def non_root_abilities(user)
    # This method will eventually get large and/or complex.  When this happens
    # we can separate it into multiple files.  Perhaps one per module (e.g.,
    # Ivy, Meca, Uma, etc.), or perhaps one per resource (e.g., Ivy::HwRack,
    # Ivy::Device, etc.).
    can :read, Ivy::Irv

    can :read, Ivy::Template
    can :manage, Ivy::Chassis, location: {rack: {user: user}}
    can :manage, Ivy::Device, chassis: {location: {rack: {user: user}}}
    can :manage, Ivy::HwRack, user: user
    can :manage, Meca::RackviewPreset, user: user

    can :read, Uma::User, id: user.id
  end

  # Despite specifying what a user can/can't do, you will eventually come
  # accross rules where you just want to stop everyone from doing it. Any rules
  # specified here will be applied to all users.
  def important_prohibitions(user)
  end
end
