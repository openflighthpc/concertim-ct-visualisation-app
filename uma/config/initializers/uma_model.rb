####################################
#
# Uma::Model
#
# Base class from which all models descend 
#
####################################

#
# Establish connection to Uma database
#
# This establishes a connection specifically to the Uma database,
# but only if we're not in the test environment (which will instead
# connect to a single SQLite database)
#

module Uma
  class Model < ActiveRecord::Base

    #
    # establish connection
    unless Rails.env.test?
      Uma::Model.establish_connection :uma
    end
   
    #
    # allow activerecord::base to be inherited 
    self.abstract_class = true

    # ensure JSON comes out as {{"ID:1... as opposed to {{"device":{"id:1
    self.include_root_in_json = false

    # :set_defaults after initialization (if it's defined)
    after_initialize :set_defaults, if: Proc.new {|r| r.new_record? && r.respond_to?(:set_defaults) }    
  end

end
