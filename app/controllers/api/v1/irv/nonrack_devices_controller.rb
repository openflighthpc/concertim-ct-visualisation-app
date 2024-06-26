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

# XXX This is completely broken !!!
class Api::V1::Irv::NonrackDevicesController < Api::V1::Irv::BaseController
  def index
    authorize! :index, Chassis
    rackableNonRackChassis = []
    dcrvShowableNonRackChassis = []
    assetList = []

    render :json => {:rackableNonRackChassis => rackableNonRackChassis, :dcrvShowableNonRackChassis => dcrvShowableNonRackChassis, :assetList => assetList.uniq}

    # if params["rackable_non_rack_ids"]
    #   rackable_non_rack_ids = params["rackable_non_rack_ids"].map{|r| r.to_i}
    #   if !rackable_non_rack_ids.empty?      
    #     rackableNonRackChassis = Chassis::NonRackChassis.rackable_non_showable.select!{|r| rackable_non_rack_ids.include? r.id}
    #   end
    # else
    #   rackableNonRackChassis = Chassis::NonRackChassis.rackable_non_showable
    # end
    #
    # if params["non_rack_ids"]
    #   non_rack_ids = params["non_rack_ids"].map{|r| r.to_i}
    #   if !non_rack_ids.empty?
    #     dcrvShowableNonRackChassis = Chassis::NonRackChassis.dcrvshowable.select!{|d| non_rack_ids.include? d.id}
    #   end
    # else
    #   dcrvShowableNonRackChassis = Chassis::NonRackChassis.dcrvshowable
    # end
    #
    # rackableNonRackChassis = rackableNonRackChassis.sort_by{|oneN| oneN.name}.map{ |oneNRC| chassis_to_hash(oneNRC) }
    # dcrvShowableNonRackChassis = dcrvShowableNonRackChassis.sort_by{|oneN| oneN.name}.map{ |oneNRC| chassis_to_hash(oneNRC) }
    # assetList = []
    # rackableNonRackChassis.each do |oneNonRackChassis|
    #   oneNonRackChassis[:template][:images].each { |key, value| assetList.push(value) }
    # end
    # dcrvShowableNonRackChassis.each do |oneNonRackChassis|
    #   oneNonRackChassis[:template][:images].each { |key, value| assetList.push(value) }
    # end
    # render :json => {:rackableNonRackChassis => rackableNonRackChassis, :dcrvShowableNonRackChassis => dcrvShowableNonRackChassis, :assetList => assetList.uniq}
  end

  def modified
    authorize! :index, Chassis
    render :json => { :timestamp => Time.new.to_i, :added => [], :modified => [], :deleted => [] }

  #   non_rack_ids = Array(params[:non_rack_ids]).collect(&:to_i)
  #   timestamp = params[:modified_timestamp]
  #   suppressAdditions = params[:suppress_additions]
  # 
  #   accessible_chassis = Chassis::NonRackChassis.accessible_by(current_ability).dcrvshowable
  #   filtered_chassis = accessible_chassis.where(id: non_rack_ids)
  #
  #   @added = suppressAdditions == "true" ? [] : accessible_chassis.excluding_ids(non_rack_ids).pluck(:id)
  #   @modified = filtered_chassis.modified_after(timestamp).pluck(:id)
  #   @deleted = non_rack_ids - filtered_chassis.pluck(:id)
  #   render :json => { :timestamp => Time.new.to_i, :added => @added, :modified => @modified, :deleted => @deleted}
  end

  private

  # The following *_to_hash methods should be replaced with presenters and rabl
  # templates if this controller is to be kept.
  def chassis_to_hash(chassis)
    {
      id: chassis.id,
      name: chassis.name,
      Slots: [device_to_slot_hash(chassis.device)],
      facing: chassis.facing,
      cols: chassis.template.columns,
      rows: chassis.template.rows,
      slots: 1,
      template: template_to_hash(chassis.template),
      type: "RackChassis"
    }
  end

  def device_to_slot_hash(device)
    {
      id: device&.id,
      col: 1,
      row: 1,
      Machine: device.nil? ? nil : device_to_hash(device),
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
      slot_id: device.id,
      column: 0,
      row: 0,
      facing: device.chassis.facing,
      template: { images: images, width: 1, height: 1, rotateClockwise: true }
    }
  end
end
