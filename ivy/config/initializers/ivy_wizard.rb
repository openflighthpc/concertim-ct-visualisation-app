module Ivy
  ####################################
  #
  # Ivy::Wizard 
  #
  # Base model from which all wizards are descended (see app/wizards).
  # These are technically NOT models, but the romance gem expects
  # any published items to be descended from AcitveRecord::Base. 
  #
  # Rather than change the romance gem, which could potentially cause
  # more problems than it fixes, and given that it will eventually be
  # deprecated, we can just call wizards "models" for the time being. 
  #
  # This way we also don't need to worry about establishing a database
  # connection.
  # 
  ####################################

  # XXX We're not using romance any more.  Pretty sure we can remove/change
  # much of this.  Not convinced that the previous claims are true either.

  class Wizard < Ivy::Model
    def attributes_from_column_definition    
      []
    end    
    def self.columns
      @columns ||= []
    end
  end
end
