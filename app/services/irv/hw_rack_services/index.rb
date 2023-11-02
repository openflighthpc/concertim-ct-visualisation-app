module Irv
  module HwRackServices
    class Index
      def self.call(user, rack_ids, slow=false)
        new(user, rack_ids, slow).call
      end

      def initialize(user, rack_ids, slow)
        @user = user
        @rack_ids = rack_ids
        @slow = slow
      end

      def call
        # New legacy moved from using Rabl to render the response to having
        # postgresql generate XML and convert that to JSON.  Part of that was due
        # to issues with Rabl and DataMapper.  We no longer use DataMapper.
        #
        # The SQL query generating the XML is complicated.  To aid in testing the
        # slow method has been kept.  The two methods should generate identical
        # JSON documents.  (Or nearly so, the XML version has everything encoded as
        # strings).
        #
        if @slow
          # This is the slow and easy to understand method.  We do jump through
          # some hoops to have the output wrapped in `{"Racks": {"Rack": <the rabl
          # template>}}`.
          @racks = @user.root? ? HwRack.all : @user.racks
          @racks = @racks.map { |rack| Api::V1::RackPresenter.new(rack) }
          renderer = Rabl::Renderer.new('api/v1/irv/racks/index', @racks, view_path: 'app/views', format: 'hash')
          {Racks: {Rack: renderer.render}}
        else
          # The fast and awkward to understand method.
          irv_rack_structure = Crack::XML.parse(InteractiveRackView.get_structure(@rack_ids, @user))
          fix_structure(irv_rack_structure)
          irv_rack_structure
        end
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
          structure['Racks']['Rack'] = [structure['Racks']['Rack']]
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
  end
end
