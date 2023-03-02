module Ivy
  class Ability
    include Emma::Ability::Common


    ################################################
    #
    # DASHBOARD PERMISSIONS 
    #
    # Things all dashboard users should be able to do 
    #
    def dashboard_permissions!(user)
      super
      # can :get_type_of, Ivy::Device
    end


    ################################################
    #
    # ACCESS CONTROL PERMISSIONS
    #
    # Things all access controlled users should be able to do.
    #
    def access_control_permissions!(user)
      super
      # can :read, Ivy::Group
      # can :read, Ivy::Device
      # can :read, Ivy::NetworkInterface
      # can :read, Ivy::Chassis
      # can :read, Ivy::HwRack
      # can :read, Ivy::ModbusConfiguration
      # can :read, Ivy::SnmpConfiguration
      # can :read, Ivy::WmiConfiguration
      # can :read, Ivy::Template
      # can :read, :device_search
      # can :configuration, Ivy::Irv
    end


    ################################################
    #
    # IMPORTANT PROHIBITIONS
    #
    # Things no user should ever be able to do.
    #
    def important_prohibitions!(user)
      super

      #
      # This is more of a knock-on - caused because they want the "set protocol" permission
      # to be set at "device level" rather than individually.
      #
      # if can? :set_protocol, Ivy::Device
      #   can :set, Ivy::ModbusRegisterGroup
      #   can :set, Ivy::ModbusRegister
      #   can :set, Ivy::SnmpMib
      #   can :set_oid, Ivy::SnmpMib
      #   can :manage, Meca::ThresholdSetAction
      # end

      # Prevent rack-destroyers from destroying occupied racks if they are not
      # also device destroyers.
      # if cannot?(:destroy, Ivy::Device) && can?(:destroy, Ivy::HwRack)
      #   cannot :destroy, Ivy::HwRack
      #   can :destroy, Ivy::HwRack, space_used: 0
      #   cannot :destroy, Ivy::Template
      # end

      # Prevent users from destroying their command
      # cannot :destroy, Ivy::Device, role: "mia"

      # Prevent user from setting protocols that have nothing to set
      # cannot(:set, Ivy::ModbusRegisterGroup) { |mrg| mrg.writeable_registers.count == 0 }
      # cannot(:set, Ivy::SnmpMib)             { |mib| mib.writeable_oids.count == 0 }

      # Prevent user from making changes to an immutable group
      # cannot [:toggle_aggregation, :administer], Ivy::Group, immutable: true

      # Prevent user from destroying an immutable or CT-provided MIB
      # cannot :destroy, Ivy::SnmpMib, immutable: true
      # cannot :destroy, Ivy::SnmpMib, provider: Ivy::SnmpMib::COMPANY_PROVIDER 

      # Prevent user from moving virtual machines
      # cannot :move, Ivy::Device, virtual?: true
    end
  end
end
