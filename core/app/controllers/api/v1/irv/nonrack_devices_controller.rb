class Api::V1::Irv::NonrackDevicesController < Api::V1::Irv::BaseController
  def index
    authorize! :index, Ivy::Chassis
    rackableNonRackChassis = []
    dcrvShowableNonRackChassis = []

    if params["rackable_non_rack_ids"]
      rackable_non_rack_ids = params["rackable_non_rack_ids"].map{|r| r.to_i}
      if !rackable_non_rack_ids.empty?      
        rackableNonRackChassis = Ivy::Chassis::NonRackChassis.rackable_non_showable.select!{|r| rackable_non_rack_ids.include? r.id}
      end
    else
      rackableNonRackChassis = Ivy::Chassis::NonRackChassis.rackable_non_showable
    end

    if params["non_rack_ids"]
      non_rack_ids = params["non_rack_ids"].map{|r| r.to_i}
      if !non_rack_ids.empty?
        dcrvShowableNonRackChassis = Ivy::Chassis::NonRackChassis.dcrvshowable.select!{|d| non_rack_ids.include? d.id}
      end
    else
      dcrvShowableNonRackChassis = Ivy::Chassis::NonRackChassis.dcrvshowable
    end

    rackableNonRackChassis = rackableNonRackChassis.sort_by{|oneN| oneN.name}.map{ |oneNRC| chassis_to_hash(oneNRC) }
    dcrvShowableNonRackChassis = dcrvShowableNonRackChassis.sort_by{|oneN| oneN.name}.map{ |oneNRC| chassis_to_hash(oneNRC) }
    assetList = []
    rackableNonRackChassis.each do |oneNonRackChassis|
      oneNonRackChassis[:template][:images].each { |key, value| assetList.push(value) }
    end
    dcrvShowableNonRackChassis.each do |oneNonRackChassis|
      oneNonRackChassis[:template][:images].each { |key, value| assetList.push(value) }
    end
    render :json => {:rackableNonRackChassis => rackableNonRackChassis, :dcrvShowableNonRackChassis => dcrvShowableNonRackChassis, :assetList => assetList.uniq}
  end

  def modified
    authorize! :index, Ivy::Chassis
    non_rack_ids = Array(params[:non_rack_ids]).collect(&:to_i)
    timestamp = params[:modified_timestamp]
    suppressAdditions = params[:suppress_additions]
  
    accessible_chassis = Ivy::Chassis::NonRackChassis.accessible_by(current_ability).dcrvshowable
    filtered_chassis = accessible_chassis.where(id: non_rack_ids)

    @added = suppressAdditions == "true" ? [] : accessible_chassis.excluding_ids(non_rack_ids).pluck(:id)
    @modified = filtered_chassis.modified_after(timestamp).pluck(:id)
    @deleted = non_rack_ids - filtered_chassis.pluck(:id)
    render :json => { :timestamp => Time.new.to_i, :added => @added, :modified => @modified, :deleted => @deleted}
  end

  private

  # The following *_to_hash methods should be replaced with presenters and rabl
  # templates if this controller is to be kept.
  def chassis_to_hash(chassis)
    {
      id: chassis.id,
      name: chassis.name,
      Slots: chassis.slots.map {|slot| slot_to_hash(slot)},
      facing: chassis.facing,
      cols: chassis.template.columns,
      rows: chassis.template.rows,
      slots: chassis.slots.count,
      template: template_to_hash(chassis.template),
      tagged_device_id: nil,
      type: chassis.type
    }
  end

  def slot_to_hash(slot)
    {
      id: slot.id,
      col: slot.chassis_row_location,
      row: slot.chassis_row.row_number - 1,
      column: slot.chassis_row_location - 1,
      Machine: slot.device.nil? ? nil : device_to_hash(slot.device),
    }
  end

  def template_to_hash(template)
    {
      rows: template.rows,
      columns: template.columns,
      images: template_images_hash(template),
      height: template.height,
      depth: template.depth,
      simple: template.simple,
      deviceType: template.chassis_type,
      model: template.model,
      rackable: template.rackable,
      padding: {
        left: template.padding_left,
        right: template.padding_right,
        top: template.padding_top,
        bottom: template.padding_bottom,
      }
    }  
  end

  def template_images_hash(template)
    template.images.nil? ? {} : YAML.load(template.images)
  end

  def device_to_hash(device)
    images = {}
    unless device.template.nil?
      images_hash = template_images_hash(device.template)
      unless images_hash.nil? || images_hash[:unit].nil?
        images = { front: device.template.images_hash[:unit] }
      end
    end

    # The column and row are decreased by 1, because the DCRV considers that
    # such indexes start from 0, but in the database, they start from 1
    {
      id: device.id,
      name: device.name,
      slot_id: device.slot_id,
      column: (device.slot.chassis_row_location - 1),
      row: (device.chassis_row.row_number - 1),
      facing: device.chassis.facing,
      type: device.type,
      template: { images: images, width: 1, height: 1, rotateClockwise: true }
    }
  end
end
