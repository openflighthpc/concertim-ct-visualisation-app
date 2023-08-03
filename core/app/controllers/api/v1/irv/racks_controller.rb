class Api::V1::Irv::RacksController < Api::V1::Irv::BaseController

  def index
    authorize! :index, Ivy::HwRack
    # New legacy moved from using Rabl to render the response to having
    # postgresql generate XML and convert that to JSON.  Part of that was due
    # to issues with Rabl and DataMapper.  We no longer use DataMapper.
    #
    # The SQL query generating the XML is complicated.  To aid in testing the
    # slow method has been kept.  The two methods should generate identical
    # JSON documents.  (Or nearly so, the XML version has everything encoded as
    # strings).

    if params[:slow]
      # This is the slow and easy to understand method.  We do jump through
      # some hoops to have the output wrapped in `{"Racks": {"Rack": <the rabl
      # template>}}`.
      @racks = Ivy::HwRack.all.map { |rack| Api::V1::RackPresenter.new(rack) }
      @racks = @racks.first if @racks.length < 2
      renderer = Rabl::Renderer.new('api/v1/irv/racks/index', @racks, view_path: 'app/views', format: 'hash')
      render json: {Racks: {Rack: renderer.render}}

    else
      # The fast and awkward to understand method.
      irv_rack_structure = Crack::XML.parse(Ivy::Irv.get_structure(params[:rack_ids], current_user))
      fix_structure(irv_rack_structure)
      render :json => irv_rack_structure.to_json
    end
  end

  def modified
    authorize! :index, Ivy::HwRack
    rack_ids = Array(params[:rack_ids]).collect(&:to_i)
    timestamp = params[:modified_timestamp]
    suppressAdditions = params[:suppress_additions]

    accessible_racks = Ivy::HwRack.accessible_by(current_ability)
    filtered_racks = accessible_racks.where(id: rack_ids)

    @added = suppressAdditions == "true" ? [] : accessible_racks.excluding_ids(rack_ids)
    @modified = filtered_racks.modified_after(timestamp)
    @deleted = rack_ids - filtered_racks.pluck(:id)
  end

  def tooltip
    @rack = Ivy::HwRack.find_by_id(params[:id])
    authorize! :read, Ivy::HwRack

    error_for('Rack') if @rack.nil?
    @rack = Api::V1::RackPresenter.new(@rack)
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
    template['images'] = JSON.parse(template['images'])

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
