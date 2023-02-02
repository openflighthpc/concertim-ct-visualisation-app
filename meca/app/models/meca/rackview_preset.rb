require 'yaml'

module Meca
  class RackviewPreset < Meca::Model

    self.table_name = 'rackview_presets'

    def values_as_json
      values ? YAML.load(values) : {}
    rescue
      {}
    end

  end
end

