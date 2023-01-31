class Api::V1::Irv::NonrackDevicesController < Api::V1::Irv::BaseController
  def index
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

    rackableNonRackChassis = rackableNonRackChassis.sort_by{|oneN| oneN.name}.map{ |oneNRC| oneNRC.to_hash }
    dcrvShowableNonRackChassis = dcrvShowableNonRackChassis.sort_by{|oneN| oneN.name}.map{ |oneNRC| oneNRC.to_hash }
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
    non_rack_ids = Array(params[:non_rack_ids]).collect(&:to_i)
    timestamp = params[:modified_timestamp]
    suppressAdditions = params[:suppress_additions]
  
    relevant_chassis = Ivy::Chassis::NonRackChassis.dcrvshowable
    @added = suppressAdditions == "true" ? [] : relevant_chassis.excluding_ids(non_rack_ids).pluck(:id)
    @modified = relevant_chassis.modified_after(timestamp).where(id: non_rack_ids).pluck(:id)
    @deleted = non_rack_ids - relevant_chassis.where(id: non_rack_ids).pluck(:id)
    render :json => { :timestamp => Time.new.to_i, :added => @added, :modified => @modified, :deleted => @deleted}
  end
end
