module Ivy
  class TemplatePersister

    def self.persist_one_with_changes(params)
      params = HashWithIndifferentAccess.new.merge(params)
      Ivy::DeviceWizard.massage_params(params)
      @template = Ivy::Template.find(params[:devices][:template_id])
      if params[:devices][:show_in_dcrv]
        params[:chassis][:show_in_dcrv] = params[:devices].delete(:show_in_dcrv)
      end
      if params[:devices][:deleted]
        return {:success => true, :device => nil, :failed_objs => [], :deleted => true, :deleted_objs => []}
      end
      failed_objs = Array.new
      chassis = nil
      device = nil
      begin
        ActiveRecord::Base.transaction do
          chassis, device, failed_objs = build_chassis(params, params[:devices].delete(:facing), failed_objs)
          if failed_objs.empty? && @device
            res = Ivy::DeviceWizard.update_or_create(@device, params)
            failed_objs += res[:failed_objs]
          end
          failed_objs.compact!
          raise ActiveRecord::RecordInvalid, failed_objs.first unless failed_objs.empty?
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
        Rails.logger.debug "An exception occured whilst saving chassis template #{@template.name}."
        Rails.logger.debug $!.message 

        roll_back_ids_and_p_keys(chassis) if chassis.id
        {:success => false, :chassis => chassis, :failed_objs => failed_objs}
      end
      {:success => failed_objs.empty?, :chassis => chassis, :failed_objs => failed_objs}
    end


    def self.build_chassis(params, facing, failed_objs)
      if facing
        params[:chassis][:facing] = facing
      end

      #
      # Because of the noddy way in which tagged devices and general device creation has been implemented, 
      # we basically need to set up chassis tagged device parameters here:
      #
      if params[:chassis] && params[:chassis][:networked_device_attributes]
        params[:chassis][:networked_device_attributes][:name]   ||= params[:chassis][:name]
        params[:chassis][:networked_device_attributes][:tagged] = true
      end

      zerou = params[:chassis].delete(:zerou)
      nonrack = params[:chassis].delete(:nonrack)
      chassis_params = params[:chassis].merge({:template_id => @template.template_id})
      @chassis = 
        if zerou.nil? && nonrack.nil?
          Ivy::Chassis::RackChassis.new chassis_params
        elsif nonrack.nil?
          Ivy::Chassis::ZeroURackChassis.new chassis_params
        else
          Ivy::Chassis::NonRackChassis.new chassis_params
        end
      begin
        failed_objs << @chassis unless @chassis.save
        failed_objs = build_chassis_rows(params, failed_objs)
        failed_objs = build_slots(params, failed_objs)
        @device = @template.simple? ? build_first_device(params) : nil
      rescue
        Rails.logger.debug "An exception occured whilst saving chassis template #{@template.name}."
        Rails.logger.debug $!.message 
        failed_objs << @chassis # we don't want a zombie chassis left
        return [@chassis, nil, failed_objs]
      end


      # And now we remove the networked device attributes because
      # whoever implemented this decided to save the device two more times, 
      # and if these params are still there it'll mean that two more get created.
      params[:chassis].delete(:networked_device_attributes)


      # Why is this save happening? Well, there isn't a comment here (shock horror) to
      # explain, but I just know bad things will happen if I remove it. Leaving it in
      # given how close to release we are. 
      if @chassis.save
        @chassis.update(params[:chassis])
      else
        failed_objs << @chassis
        failed_objs << @device
      end
      @chassis.instance_variable_set("@template_name",@template.name)
      [@chassis, @device, failed_objs]
    end


    def self.build_chassis_rows(params, failed_objs)
      @template.rows.to_i.times do |i|
        cr = @chassis.chassis_rows.build
        failed_objs << @chassis.chassis_rows[i] unless @chassis.chassis_rows[i].save
      end
      failed_objs
    end


    def self.build_slots(params, failed_objs)
      @chassis.chassis_rows.each_with_index do |oneCR, i|
        @template.columns.times do |s| 
          sl = @chassis.chassis_rows[i].slots.build
          @chassis.chassis_rows[i].slots[s].chassis_row_location = s + 1
          failed_objs << @chassis.chassis_rows[i].slots[s] unless @chassis.chassis_rows[i].slots[s].save
        end
      end
      failed_objs
    end


    def self.build_first_device(params)
      @device = @chassis.chassis_rows.first.slots.first.build_device(params[:devices])
      build_network_interfaces if @device.isla?
      # build_psus
      @device
    end


    def self.roll_back_ids_and_p_keys(chassis)
      # XXX Do we still need this.  Has ActiveRecord still not figured out to
      # do this itself?
      onec = Ivy::Chassis.find(chassis.id)
      onec.destroy unless onec.nil?
      chassis.id = nil
      chassis.instance_variable_set("@new_record", true)

      chassis.chassis_rows.each do |cr|
        cr.id = nil
        cr.instance_variable_set("@new_record", true)

        cr.slots.each do |sl|
          sl.id = nil
          sl.instance_variable_set("@new_record", true)
        end
      end
    end
  end
end
