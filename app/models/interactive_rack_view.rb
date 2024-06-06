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

class InteractiveRackView

  ############################
  #
  # Class Methods
  #
  ############################

  # ------------------------------------
  # Canvas functions

  class << self
    def get_structure(racks=nil, user=nil)
      unless racks || user
        Rails.logger.debug("Argument error: must have racks or a user")
        return ['<error>Missing arguments</error>']
      end

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
      if user
        permitted_ids = HwRack.accessible_by(user.ability).pluck('id')
        if requested_ids.nil?
          permitted_ids
        else
          requested_ids & permitted_ids
        end
      else
        requested_ids
      end
    end

    def role_query(user)
      return unless user

      if user.root?
        "( SELECT 'superAdmin' as \"teamRole\" ) as \"teamRole\","
      else
        "( SELECT TR.role AS \"teamRole\" FROM team_roles TR WHERE TR.team_id = R.team_id AND TR.user_id = '#{user.id.to_s}' LIMIT 1) AS \"teamRole\","
      end
    end

    def generate_sql(racks, user)
      ids = rack_ids(racks, user)
      sanitized_ids = ids.map { |id| "'#{ApplicationRecord.sanitize_sql(id)}'" }.join(',')
      condition = ids.empty? ? " WHERE 1 = 0 " : " WHERE R.id in (#{sanitized_ids})"

      ret = (<<SQL)
WITH sorted_racks AS (
        SELECT racks.id AS id, racks.name AS name, racks.u_height AS u_height, racks.status AS status, racks.template_id AS template_id, racks.team_id AS team_id
          FROM racks
          JOIN teams as teams ON racks.team_id = teams.id
      ORDER BY LOWER(teams.name)
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
                       #{role_query(user)}
                       ( SELECT id FROM sorted_racks OFFSET (SELECT row_num FROM (SELECT id,row_number() OVER () AS row_num FROM sorted_racks) t WHERE id=R.id) LIMIT 1) AS "nextRackId"),
                       ( SELECT XmlElement( name "owner", XmlAttributes (O.id, O.name))
                           FROM teams O WHERE O.id = R.team_id LIMIT 1 
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
                                                                                                              D.type AS "type"
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
