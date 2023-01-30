module Ivy
  class Irv 

    ############################
    #
    # Class Methods
    #
    ############################

    # ------------------------------------
    # Canvas functions

    def self.get_canvas_config
      racks_config_hash = Ivy::HwRack.get_canvas_config
      irv_config_hash   = JSON.parse(File.read(Engine.root.join("app/views/ivy/irvs/_configuration.json")))
      racks_config_hash.each{|k,v| irv_config_hash[k] = irv_config_hash[k].merge(racks_config_hash[k]) }
      irv_config_hash
    end
  end
end
