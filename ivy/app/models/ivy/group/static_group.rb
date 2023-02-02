module Ivy
  class Group
    class StaticGroup < Group

      has_many :g_members, class_name: 'Ivy::GroupMember', foreign_key: :group_id, dependent: :destroy

      ############################
      #
      # Instance Methods            
      #
      ############################

      def member_ids(reload=false, show_hidden=false) 
        g_members.pluck(:device_id)
      end

    end
  end
end
