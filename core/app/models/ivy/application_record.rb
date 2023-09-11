module Ivy
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    # ensure JSON comes out as {{"ID:1... as opposed to {{"device":{"id:1
    self.include_root_in_json = false

    # ensure that the STI column does not store "Ivy::Device::", meaning that legacy
    # code (which wasn't namespaced) can still get at the devices.
    self.store_full_sti_class = false

    # :set_defaults after initialization (if it's defined)
    after_initialize :set_defaults, if: Proc.new {|r| r.new_record? && r.respond_to?(:set_defaults) }
  end
end
