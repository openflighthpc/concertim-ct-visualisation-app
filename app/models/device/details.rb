class Device::Details < ApplicationRecord
  self.abstract_class = true

  has_one :device
end
