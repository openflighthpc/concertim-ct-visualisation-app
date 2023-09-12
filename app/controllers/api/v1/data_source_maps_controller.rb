class Api::V1::DataSourceMapsController < Api::V1::ApplicationController
  load_and_authorize_resource :data_source_map, class: DataSourceMap

  # Returns a data source map in a format that is suitable for use by the
  # metric reporting daemon.
  def index
    body = { }
    @data_source_maps.each do |dsm|
      g = dsm.map_to_grid
      c = dsm.map_to_cluster
      h = dsm.map_to_host
      next if h.nil?
      body[g] ||= {}
      body[g][c] ||= {}
      body[g][c][h] = dsm.device_id.to_s
    end

    render json: body
  end
end
