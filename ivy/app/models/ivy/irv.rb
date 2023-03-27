module Ivy
  class Irv 

    ############################
    #
    # Class Methods
    #
    ############################

    # ------------------------------------
    # Canvas functions

    class << self
      def get_structure(racks=nil)
        sql = generate_sql(racks)
        begin
          xml = ApplicationRecord.connection.exec_query(sql).rows.join
        rescue
          Rails.logger.debug("An exception occured whilst generating IRV structure")
          Rails.logger.debug($!.class)
          Rails.logger.debug($!.message)
          ['<error>Invalid SQL query</error>']
        end
      end

      def get_canvas_config
        racks_config_hash = Ivy::HwRack.get_canvas_config
        irv_config_hash   = JSON.parse(File.read(Engine.root.join("app/views/ivy/irvs/_configuration.json")))
        racks_config_hash.each{|k,v| irv_config_hash[k] = irv_config_hash[k].merge(racks_config_hash[k]) }
        irv_config_hash
      end

      private

      def generate_sql(racks)
        condition = case racks
                    when Array
                      " WHERE R.id in (#{racks.map{|rack_id| rack_id.to_i}.join(',')})"
                    when Integer
                      " WHERE R.id = #{racks}"
                    when String
                      " WHERE R.id = #{racks}"
                    else
                      ""
                    end

ret = (<<SQL)
WITH sorted_racks AS (
SELECT id, name, u_height, template_id FROM racks ORDER BY SUBSTRING( "name" FROM E'^(.*?)(\\\\d+)?$'), lpad(substring( "name" from E'(\\\\d+)$'), 30, '0') asc
)
SELECT
  XmlElement( name "Racks",
   XmlAgg( 
    XmlElement( name "Rack", 
                XmlAttributes( R.id as "id",
                               R.name as "name",
                               R.u_height as "uHeight" ,
                               ( SELECT id from sorted_racks offset (select row_num from (select id,row_number() over () as row_num from sorted_racks) t where id=R.id) limit 1) as "nextRackId"),
                               ( select XmlAgg( XmlElement( name "template", XmlAttributes (T.template_id as "id",T.name,T.manufacturer,T.model,T.rackable,T.product_url as "url",
                                                                                            T.images,T.height,T.rows,T.columns,T.rack_repeat_ratio,T.depth,
                                                                                            T.padding_left,T.padding_right,T.padding_top,T.padding_bottom,T.simple
                                                                                            ))) from templates T where T.template_id = R.template_id limit 1 ),
                               ( SELECT XmlAgg( 
                                         XmlElement( name "Chassis", 
                                                     XmlAttributes( C.id,
   		                                                    C.name,
		  		                                    C.type,
                                                                    C.facing,
                                                                    C.rows,
                                                                    C.slots,
                                                                    (C.slots / C.rows) as cols,
                                                                    C.rack_start_u as "uStart",
                                                                    C.rack_end_u as "uEnd",
                                                                    ( select DD.id from devices DD where DD.base_chassis_id = C.id and DD.tagged = true) as "tagged_device_id"),
                                                                    ( select XmlAgg( XmlElement( name "template", XmlAttributes (T.template_id as "id",T.name,T.manufacturer,T.model,T.rackable,
                                                                                                                                 T.images,T.height,T.rows,T.columns,T.rack_repeat_ratio,T.depth,
                                                                                                                                 T.padding_left,T.padding_right,T.padding_top,T.padding_bottom,T.simple
                                                                                                                                 ))) from templates T where T.template_id = C.template_id limit 1 ),
					  			    ( select XmlAgg(
                                                                              XmlElement( name "Slots",
                                                                                          XmlAttributes( S.id as "id",
                                                                                                         S.chassis_row_location as "col",
                                                                                                         CR.row_number as "row" ),
                                                                                          ( select XmlAgg( 
                                                                                                   XmlElement( name "Machine",
                                                                                                                XmlAttributes( D.id as "id",
                                                                                                                               D.type as "type",
                                                                                                                               D.name as "name" )
                                                                                                   )) from devices D where D.slot_id = S.id
                                                                                          )
                                                                              )
                                                                             ) from Slots S
                                                                               join chassis_rows CR on CR.id = S.chassis_row_id
                                                                               WHERE CR.base_chassis_id = C.id
								     )
                                         )
                                        ) from ( select id,
					         name,
					         type,
                                                 facing,
                                                 rack_start_u,
                                                 rack_end_u,
                                                 template_id, 
                                                 (select count(CR.id) from chassis_rows CR where CR.base_chassis_id = C.id) as rows,
                                                 (select count(SL.id) from slots SL join chassis_rows CR on SL.chassis_row_id = CR.id WHERE CR.base_chassis_id = C.id) as slots from base_chassis C where C.rack_id = R.id group by C.id, C.name, C.type, C.facing, C.rack_start_u, C.rack_end_u, C.template_id) as C
                               )      
                )
    )
   ) from sorted_racks R 
SQL

        ret + condition
      end
    end
  end
end
