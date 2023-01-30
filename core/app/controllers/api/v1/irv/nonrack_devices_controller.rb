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

end
