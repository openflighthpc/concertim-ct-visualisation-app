module Ivy
  class HwRack < Ivy::Model

    self.table_name = "racks"

    ############################
    #
    # Class Methods
    #
    ############################

    # ------------------------------------
    # Canvas functions

    def self.get_canvas_config
      JSON.parse(File.read(Engine.root.join("app/views/ivy/racks/_configuration.json")))
    end

  end
end
