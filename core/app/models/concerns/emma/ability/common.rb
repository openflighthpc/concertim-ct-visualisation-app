#
# Emma::Ability::Common
#
# Mixin for functionality common to all abilities accross all engines. Main features are:
#
# * The constructor
# * The cancan ability module
# * The method that applies permissions to users
# * The method that sets up action aliases
#
# Defalut permissions for each type of user (dashboard, access_controlled and root) can
# be found in the Emma::Ability::BasePermissions module.
#
module Emma
  module Ability
    module Common
      include CanCan::Ability
      include Emma::Ability::BasePermissions

      #
      # initializer
      #
      def initialize(user)
        alias_actions!
        enable_abilities! user || User.new
      end


      private
      #
      # enable_abilities!
      #
      # This method is the heart of the module - it is responsible for "activating"
      # the abilities for a given user. 
      # 
      def enable_abilities!(user)
        #
        # Dashboard users are super-nerfed - they get NO privaledges other than one or two
        # and are thus completely excluded from any additional access rules. 
        # dashboard_permissions!(user) and return if user.dashboard?

        if user.root?
          root_permissions! user
        else
          access_control_permissions! user
        end

        important_prohibitions! user
      end


      #
      # alias_actions!
      #
      # Cancan action aliases. Usage is two-fold - Firstly you might want 
      # to bunch several actions under one common heading, e.g. consider
      # "administer" to be the basic CRUD actions.
      #
      # There are also allowances made here for when people have implemented things
      # in a non-REST way (e.g. the ability to "OIDS" an "SNMP Configuration") - these
      # will gradually be deprecated as the code is refactored.
      #
      # THIS IS REALLY, REALLY AWFUL. Please do not add to this already-too-long
      # list of places where people have not coded in a RESTful way. The idea is that
      # this list gets SMALLER over time, not larger.
      #
      def alias_actions!
        # alias_action :create, :update, :destroy, :toggle, to: :administer
        # alias_action :list, to: :index
        # # alias_action :wizard, to: :create
        # alias_action :reposition, to: :move
      end
    end
  end
end
