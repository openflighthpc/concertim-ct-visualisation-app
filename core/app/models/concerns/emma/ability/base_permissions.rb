#
# Emma::Ability::BasePermissions
#
# Users will have some "base abilities" which we want to apply regardless of what engine we are in. For example, 
# it is a general rule that administrator users can manage everything.
#
# These are specified here. Overriding these methods should be accompanied by a call to "super" otherwise
# these base rules will be skipped. As well as specifying base rules, each user by defalt should get
# the abilities of the user-levels below them.
#
module Emma
  module Ability
    module BasePermissions


      #
      # dashboard_permissions!
      #
      # Base abilities for a dashboard user (completely blind)
      #
      def dashboard_permissions!(user)
        cannot :read, :all
      end


      #
      # root_permissions!
      # 
      # Base permissions for a root user (can essentially do anything)
      #
      def root_permissions!(user)
        can :manage, :all
      end


      #
      # access_control_permissions!
      # 
      # Base abilities for access controlled users
      #
      def access_control_permissions!(user)
        # return unless user.access_controlled?
        # @access_control_activator ||= Emma::AccessControlActivator.new(self, user)
        # @access_control_activator.register_resource_level_permissions!
      end


      #
      # important_prohibitions
      #
      # Despite specifying what a user can/can't do, you will eventually
      # come accross rules where you just want to stop everyone from doing it (e.g. 
      # destroying the command device). Any rules specified in the "final prohibition" 
      # method will be applied to all users.
      #
      def important_prohibitions!(user)
      end
    end
  end
end
