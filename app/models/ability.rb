#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

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
    can [:read, :usage_limits], Team, id: @user.team_ids
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
