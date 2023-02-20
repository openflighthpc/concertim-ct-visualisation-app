module Ivy
  class DeviceWizard < Ivy::Wizard
    def self.massage_params(params)
      # XXX Which of these do we still want/need?
      params[:bmc_entities] = params.delete(:bmcs)
      params[:data_source_maps] = params.delete(:datamaps)
      params[:network_interfaces] = params.delete(:nics)
      params[:power_supplies] = params.delete(:psus)
      params[:virtual_servers] = params.delete(:virtual)
      devt = massage_device_params(params)
      devt
    end

    def self.massage_device_params(params)
      # Ensure that the params for the device are accessible through both
      # params[:devices] and params["#{device_type.to_s.pluralize}".to_sym]
      device_type_from_params = params[:devices].delete(:type)
      if device_type_from_params == "Server"
        device_type = :server
      elsif device_type_from_params == "Sensor"
        device_type = :sensor
      elsif device_type_from_params == "ManagedDevice"
        device_type = :managed_device
      elsif device_type_from_params == "MiscellaneousDevice"
        device_type = :miscellaneous_device
      elsif device_type_from_params == "Switch"
        device_type = :switch
      elsif device_type_from_params == "PowerStrip"
        device_type = :power_strip
      else
        params[:devices] = Hash.new
        device_type = nil
      end
      device_type
    end

    def self.update_or_create(device, params)
      # This determines the new template that the user has selected to associate the device to. We reload the new template and re-associate it
      # to this new template
      if params.has_key?(:devices) && params[:devices].has_key?(:manufacturer) && params[:devices].has_key?(:template_id)
        new_template = Ivy::Template.find(params[:devices][:template_id])
        params[:devices][:model] = new_template.model
        params[:devices][:template_id] = new_template.template_id
      end

      failed_objs = Array.new
      deleted_objs = Array.new
      altered_objs = Array.new
      # persisted_objs = get_persisted_associations(device)
      begin
        ActiveRecord::Base.transaction do
          # XXX This block will be deleted when in 'moving device' we enable selecting front or rear available slots.
          # That will be done in miranda... In the mean time, this will delete the parameter facing from the params, and
          # use it to update the chassis...
          facing = params[:devices].delete(:facing)
          if facing
            device.chassis.facing = facing
          end
          res = do_update_or_create(device, params)
          failed_objs += res[:failed_objs]
          deleted_objs += res[:deleted_objs]
          failed_objs.compact!
          deleted_objs.compact!
          altered_objs += res[:altered_objs]
          raise ActiveRecord::RecordInvalid, failed_objs.first unless failed_objs.empty?
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::RecordNotFound
        Rails.logger.debug "An exception occured whilst saving device #{device.id || 'new device'}."
        Rails.logger.debug $!.message 
        # roll_back_ids_and_p_keys(device, persisted_objs)
        {:success => false, :device => device, :failed_objs => failed_objs, :deleted_objs => deleted_objs, :altered_objs => altered_objs}
      end
      {:success => failed_objs.empty?, :device => device, :failed_objs => failed_objs, :deleted_objs => deleted_objs, :altered_objs => altered_objs}
    end

    def self.update_associations(data)
      data[:associations].each do |method, *assoc|
        res = self.send(method, data[:device], data[:params], *assoc)
        data[:objs][:failed] += res[:failed_objs]
        data[:objs][:deleted] += res[:deleted_objs]
        data[:objs][:altered] += res[:altered_objs]
      end
      data
    end


    def self.do_update_or_create(device, params)
      failed_objs = []
      deleted_objs = []
      altered_objs = []
      res = update_device(device, params)
      altered_objs << device if res[:altered]
      failed_objs << device unless res[:success]

      # Save the network interfaces first as the BMC entity and data source map
      # may depened upon the result of the device's IP address.
      result = update_associations({
        :device => device,
        :params => params,
        :objs => {:failed => failed_objs, :deleted => deleted_objs, :altered => altered_objs},
        :associations => [
          # [ :update_has_many_association, :network_interfaces, Ivy::NetworkInterface],
          # [ :update_has_one_association,  :bmc_entity,         Ivy::BmcEntity],
          # [ :update_has_many_association, :virtual_servers,    Ivy::Device::Server],
          # [ :update_modbus_configuration ],
          # [ :update_snmp_configuration ],
          # [ :update_wmi_configuration ],
          # [ :update_power_supplies ]
        ]
      })

      failed_objs = result[:objs][:failed]
      deleted_objs = result[:objs][:deleted]
      altered_objs = result[:objs][:altered]

      if (device.respond_to?(:virtual_servers)) && (device.virtual_servers.size > 0) && (device.hypervisor.nil? or device.hypervisor.empty?)
        device.errors.add :hypervisor, "cannot be empty if virtual machines are being hosted in this server."
        failed_objs << device
      end

      {:failed_objs => failed_objs, :deleted_objs => deleted_objs, :altered_objs => altered_objs}
    end

    def self.update_device(device, params)
      p = params[:devices]
      if p.nil?
        {:success => true, :altered => false}
      else
        p = p.symbolize_keys
        p.delete(:id)
        p.delete(:type)
        success = device.update(p)
        {:success => success, :altered => true}
      end
    end


    # def self.roll_back_ids_and_p_keys(device, persisted_objs)
    #   # If device was new (if we are rolling back a device creation) then delete the memcache entry
    #   if device.was_a_new_record?
    #     device.destroy_interchange
    #   end
    #
    #   (get_all_associations(device) - persisted_objs).each do |m|
    #     m.id = nil
    #     m.instance_variable_set("@new_record", true)
    #   end
    #   if device.new_record?
    #     unset_has_one_foreign_key(device, :bmc_entity, :networked_device_id)
    #     unset_has_one_foreign_key(device, :data_source_map, :device_id)
    #     unset_has_one_foreign_key(device, :modbus_configuration, :modbus_gateway_id)
    #     unset_has_one_foreign_key(device, :snmp_configuration, :networked_device_id)
    #     unset_has_one_foreign_key(device, :wmi_configuration, :networked_device_id)
    #     unset_has_many_foreign_key(device, :network_interfaces, :networked_device_id)
    #     unset_has_many_foreign_key(device, :virtual_servers, :server_id)
    #   end
    #   if ! virtual(device) && ( slot = device.slot ).new_record?
    #     if device.simple?
    #       unset_has_many_foreign_key(slot.chassis_row.base_chassis.chassis_rows.first.slots.first, :power_supplies, :slot_id)
    #     else
    #       unset_has_many_foreign_key(slot, :power_supplies, :slot_id)
    #     end
    #     if ( chassis = slot.chassis_row.base_chassis ).new_record?
    #       unset_has_many_foreign_key(chassis, :power_supplies, :base_chassis_id)
    #     end
    #   end
    #   fix_modbus_register_groups_method(device)
    #   fix_snmp_mibs_method(device)
    #   fix_wmi_selections_method(device)
    # end

  end
end
