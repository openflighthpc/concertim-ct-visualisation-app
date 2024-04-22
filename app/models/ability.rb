class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user || User.new
    enable_abilities
  end

  private

  def enable_abilities
    if @user.root?
      root_abilities
    else
      non_root_abilities
    end

    important_prohibitions
  end

  # Abilities for root users (can essentially do anything, except launch clusters).
  def root_abilities
    can :manage, :all

    cannot :read, ClusterType
    cannot :create, Cluster

    # Don't allow any admin users to be deleted.
    cannot :destroy, User, root: true

    cannot :manage, TeamRole, team: Team.where(single_user: true)
  end

  # Abilities for non-root users.
  def non_root_abilities
    # This method will eventually get large and/or complex.  When this happens
    # we can separate it into multiple files.
    can :read, InteractiveRackView

    can :read, Template
    can :read, Chassis, location: {rack: {team_id: @user.team_ids }}
    can :read, Device, chassis: {location: {rack: {team_id: @user.team_ids }}}
    can [:read, :devices], HwRack, team_id: @user.team_ids
    can :manage, Chassis, location: {rack: {team_id: @user.teams_where_admin.pluck(:id) }}
    can :manage, Device, chassis: {location: {rack: {team_id: @user.teams_where_admin.pluck(:id) }}}
    can :manage, HwRack, team_id: @user.teams_where_admin.pluck(:id)

    can :manage, RackviewPreset, user: @user

    can :read, ClusterType
    can :create, Cluster, team_id: @user.teams_where_admin.pluck(:id)

    can :read, KeyPair, user: @user
    can :create, KeyPair, user: @user
    can :destroy, KeyPair, user: @user

    can [:read, :update], User, id: @user.id
    can [:read, :quotas], Team, id: @user.team_ids
    can :manage, TeamRole, team: @user.teams_where_admin.where(single_user: false)

    # Invoice is an ActiveModel::Model, but not an ActiveRecord::Base.  Setting
    # abilities like this might not work too well.  Or perhaps its fine.
    can :read, Invoice, account: @user.team_roles.where(role: "admin").map(&:team)
  end

  # Despite specifying what a user can/can't do, you will eventually come
  # across rules where you just want to stop everyone from doing it. Any rules
  # specified here will be applied to all users.
  def important_prohibitions
  end
end
