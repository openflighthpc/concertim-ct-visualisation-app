class InteractiveRackView

  ############################
  #
  # Class Methods
  #
  ############################

  # ------------------------------------
  # Canvas functions

  class << self
    def get_structure(racks=nil, user)
      sql = generate_sql(racks, user)
      begin
        xml = ApplicationRecord.connection.exec_query(sql).rows.join
      rescue
        Rails.logger.debug("An exception occurred whilst generating IRV structure")
        Rails.logger.debug($!.class)
        Rails.logger.debug($!.message)
        ['<error>Invalid SQL query</error>']
      end
    end

    def get_canvas_config
      racks_config_hash = HwRack.get_canvas_config
      irv_config_hash   = JSON.parse(File.read(Rails.root.join("app/views/interactive_rack_views/_configuration.json"))).tap do |config|
        settings = Setting.first
        if settings && settings.metric_refresh_interval.present?
          config['CONTROLLER']['minMetricPollRate'] = settings.metric_refresh_interval * 1000
          config['VIEWMODEL']['startUp']['metricPollRate'] = settings.metric_refresh_interval * 1000
        end
      end
      racks_config_hash.each{|k,v| irv_config_hash[k] = irv_config_hash[k].merge(racks_config_hash[k]) }
      irv_config_hash
    end

    private

    def rack_ids(racks, user)
      requested_ids =
        case racks
        when Array
          racks
        when String
          [racks]
        else
          nil
        end
      permitted_ids = HwRack.accessible_by(user.ability).pluck('id')
      if requested_ids.nil?
        permitted_ids
      else
        requested_ids & permitted_ids
      end
    end

    def generate_sql(racks, user)
      ids = rack_ids(racks, user)
      sanitized_ids = ids.map { |id| "'#{ApplicationRecord.sanitize_sql(id)}'" }.join(',')
      condition = ids.empty? ? " WHERE 1 = 0 " : " WHERE R.id in (#{sanitized_ids})"

      ret = (<<SQL)
WITH sorted_racks AS (
        SELECT racks.id AS id, racks.name AS name, racks.u_height AS u_height, racks.status AS status, ROUND(racks.cost, 2) AS cost, racks.template_id AS template_id, racks.user_id AS user_id
          FROM racks
          JOIN users as users ON racks.user_id = users.id
      ORDER BY LOWER(users.name)
             , SUBSTRING("racks"."name" FROM E'^(.*?)(\\\\d+)?$')
             , LPAD(SUBSTRING( "racks"."name" FROM E'(\\\\d+)$'), 30, '0') ASC
)
SELECT
  XmlElement( name "Racks",
    XmlAgg( 
      XmlElement( name "Rack", 
        XmlAttributes( R.id AS "id",
                       R.name AS "name",
                       R.u_height AS "uHeight" ,
                       R.status AS "buildStatus" ,
                       cast(R.cost as money) AS "cost",
                       ( SELECT id FROM sorted_racks OFFSET (SELECT row_num FROM (SELECT id,row_number() OVER () AS row_num FROM sorted_racks) t WHERE id=R.id) LIMIT 1) AS "nextRackId"),
                       ( SELECT XmlElement( name "owner", XmlAttributes (O.id, O.name, O.login))
                           FROM users O WHERE O.id = R.user_id LIMIT 1 
                       ),
                       ( SELECT XmlAgg( XmlElement( name "template",
                                          XmlAttributes (T.id,T.name,T.model,T.rackable,
                                                         T.images,T.height,T.rows,T.columns,T.rack_repeat_ratio,T.depth,
                                                         T.padding_left,T.padding_right,T.padding_top,T.padding_bottom,T.simple
                                                        )
                                      ))
                           FROM templates T WHERE T.id = R.template_id LIMIT 1 
                       ),
                       ( SELECT XmlAgg( XmlElement( name "Chassis", 
                                          XmlAttributes( C.id,
   		                                         C.name,
		  		                         C.type,
                                                         C.facing,
                                                         C.rows,
                                                         C.slots,
                                                         (C.slots / C.rows) AS cols,
                                                         C.start_u AS "uStart",
                                                         C.end_u AS "uEnd"),
                                                         ( SELECT XmlAgg( XmlElement( name "template",
                                                                            XmlAttributes (T.id,T.name,T.model,T.rackable,
                                                                                           T.images,T.height,T.rows,T.columns,T.rack_repeat_ratio,T.depth,
                                                                                           T.padding_left,T.padding_right,T.padding_top,T.padding_bottom,T.simple
                                                                                          )
                                                                         ))
                                                             FROM templates T WHERE T.id = C.template_id LIMIT 1 
                                                         ),
                                                         ( SELECT XmlAgg( XmlElement( name "Slots",
                                                                            XmlAttributes( S.id AS "id",
                                                                                           (SELECT 1) AS "col",
                                                                                           (SELECT 1) AS "row" 
                                                                                         ),
                                                                            ( SELECT XmlAgg( XmlElement( name "Machine",
                                                                                               XmlAttributes( D.id AS "id",
                                                                                                              D.name AS "name",
                                                                                                              D.status AS "buildStatus",
                                                                                                              cast(D.cost as money) AS "cost" 
                                                                                                            )
                                                                                           ))
                                                                                FROM devices D WHERE D.id = S.id
                                                                            )
                                                                        ))
                                                             FROM ( SELECT id
                                                                      FROM devices D
                                                                     WHERE D.base_chassis_id = C.id
                                                                  ) AS S
                                                         )
                                      ))
                           FROM ( SELECT C.id,
					 name,
					 (select 'RackChassis') as type,
                                         L.facing,
                                         L.start_u,
                                         L.end_u,
                                         template_id, 
                                         (SELECT 1) AS rows,
                                         (SELECT 1) AS slots
                                    FROM base_chassis C
                                    JOIN locations L ON L.id = C.location_id
                                   WHERE L.rack_id = R.id
                                GROUP BY C.id, C.name, L.facing, L.start_u, L.end_u, C.template_id
                                ) as C
                       )      
                )
    )
   ) FROM sorted_racks R 
SQL

      ret + condition
    end
  end
end
