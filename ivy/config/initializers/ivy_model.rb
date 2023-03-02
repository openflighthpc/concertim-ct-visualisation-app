####################################
#
# Ivy::Model
#
# base class from which all models descend 
#
####################################

#
# Establish connection to IVY database
#
# this establishes a connection specifically to the Ivy database,
# but only if we're not in the test environment (which will instead
# connect to a single SQLite database)
#

module Ivy
  class Model < ActiveRecord::Base

    #
    # establish connection
    unless Rails.env.test?
      Ivy::Model.establish_connection :ivy
    end
   
    #
    # allow activerecord::base to be inherited 
    self.abstract_class = true

    # ensure JSON comes out as {{"ID:1... as opposed to {{"device":{"id:1
    self.include_root_in_json = false

    # ensure that the STI column does not store "Ivy::Device::", meaning that legacy
    # code (which wasn't namespaced) can still get at the devices.
    self.store_full_sti_class = false

    # # force "all" to return a relation rather than an array.
    # def self.all
    #   scoped
    # end

    # :set_defaults after initialization (if it's defined)
    after_initialize :set_defaults, if: Proc.new {|r| r.new_record? && r.respond_to?(:set_defaults) }    
  end

end
