class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  self.store_full_sti_class = false
end
