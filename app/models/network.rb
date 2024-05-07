class Network < Device
  validate :has_network_details
  validate :has_network_template

  #############################
  #
  # CONSTANTS
  #
  ############################

  VALID_STATUS_ACTION_MAPPINGS = {
    "IN_PROGRESS" => [],
    "FAILED" => [],
    "ACTIVE" => [],
    "STOPPED" => [],
    "SUSPENDED" => []  }

  private

  def has_network_details
    unless details_type == 'Device::NetworkDetails'
      self.errors.add(:details_type, 'must have network details')
    end
  end

  def has_network_template
    unless device.template.tag == 'volume'
      self.errors.add(:template, 'must use the network template')
    end
  end
end
