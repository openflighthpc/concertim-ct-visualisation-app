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

  # Abilities for root users (can essentially do anything, except launch clusters).
  def root_abilities(user)
    can :manage, :all

    cannot :read, ClusterType
    cannot :create, Cluster

    # Don't allow any admin users to be deleted.
    cannot :destroy, User, root: true
  end

  # Abilities for non-root users.
  def non_root_abilities(user)
    # This method will eventually get large and/or complex.  When this happens
    # we can separate it into multiple files.
    can :read, InteractiveRackView

    can :read, Template
    can :manage, Chassis, location: {rack: {user: user}}
    can :manage, Device, chassis: {location: {rack: {user: user}}}
    can :manage, HwRack, user: user
    can :manage, RackviewPreset, user: user

    can :read, ClusterType
    can :create, Cluster if user.enough_credits_to_create_cluster?

    can :read, KeyPair, user: user
    can :create, KeyPair, user: user
    can :destroy, KeyPair, user: user

    can [:read, :update], User, id: user.id

    # Invoice is an ActiveModel::Model, but not an ActiveRecord::Base.  Setting
    # abilities like this might not work too well.  Or perhaps its fine.
    can :read, Invoice, account: user
  end

  # Despite specifying what a user can/can't do, you will eventually come
  # across rules where you just want to stop everyone from doing it. Any rules
  # specified here will be applied to all users.
  def important_prohibitions(user)
  end
end
