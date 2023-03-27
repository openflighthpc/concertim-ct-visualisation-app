class Api::V1::Irv::RacksController < Api::V1::Irv::BaseController

  def index
    authorize! :index, Ivy::HwRack
    # As RABL has quite a serious issue where it casts the collection as an array
    # before itterating over it, causeing Data Mapper which lazy loads any way
    # to call for each item indevidually, rather that with a single shot request
    # for it all.
    #
    # Because of this we will get the database to produce what we need directly
    # in the form of XML, convert it to JSON and send it back to the requestor
    #
    # Uncomment the bellow to use the new ultra fast query method!
    #
    irv_rack_structure = Crack::XML.parse(Ivy::Irv.get_structure(params[:rack_ids]))
    fix_structure(irv_rack_structure)
    render :json => irv_rack_structure.to_json

    # If you want XML uncomment the below
    #
    # render :xml => irv_rack_structure

    #XXX This is the slow method, comment this out when using the above
    #
    # @racks = Ivy::HwRack.all
   end

  def modified
    authorize! :index, Ivy::HwRack
    rack_ids = Array(params[:rack_ids]).collect(&:to_i)
    timestamp = params[:modified_timestamp]
    suppressAdditions = params[:suppress_additions]

    @added = suppressAdditions == "true" ? [] : Ivy::HwRack.excluding_ids(rack_ids)
    @modified = Ivy::HwRack.where(id: rack_ids).modified_after(timestamp)
    @deleted = rack_ids - Ivy::HwRack.where(id: rack_ids).pluck(:id)
  end

  def tooltip
    @rack = Ivy::HwRack.find_by_id(params[:id])
    authorize! :read, Ivy::HwRack

    error_for('Rack') if @rack.nil?
  end

  private

  def fix_structure(structure)
    # Parsing XML is a pain.
    #
    #   <Racks></Racks>
    #   <Racks><Rack></Rack></Racks>
    #   <Racks><Rack></Rack><Rack></Rack></Racks>
    #
    # The above doesn't parse consistently.  `Racks['Rack']` might be `nil`, a
    # single object, or an array of objects. We fix that here and also fix an
    # image serialization issue.

    if structure['Racks'].nil?
      # When we have no racks defined.
      structure['Racks'] = {'Rack': []}
      return

    elsif structure['Racks']['Rack'].is_a?(Array)
      # When we have two or more racks defined.
      structure['Racks']['Rack'].each { |s| fix_images(s) }
      return

    else

      # We have a single rack defined.
      fix_images(structure['Racks']['Rack'])
    end
  end

  def fix_images(structure)
    # Convert images from a JSON string to a YAML string.
    # XXX Update model to serialize this column.
    # XXX Update JS to accept a JSON object for these attributes.
    template = structure['template']
    template['images'] = JSON.parse(template['images']).symbolize_keys.to_yaml

    case structure['Chassis']
    when nil
      # Nothing to do.
    when Array
      structure['Chassis'].each { |c| fix_images(c) }
    else
      fix_images(structure['Chassis'])
    end
  end
end
