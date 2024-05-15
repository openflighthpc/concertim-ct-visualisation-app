class Network < Device

  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.valid_statuses
    %w(IN_PROGRESS FAILED ACTIVE STOPPED)
  end

  def self.valid_status_action_mappings
    {
      "IN_PROGRESS" => [],
      "FAILED" => %w(destroy),
      "ACTIVE" => %w(destroy),
      "STOPPED" => %w(destroy)
    }
  end


  ####################################
  #
  # Validations
  #
  ####################################

  validate :has_network_details
  validate :has_network_template

  private

  def has_network_details
    unless details_type == 'Device::NetworkDetails'
      self.errors.add(:details_type, 'must have network details')
    end
  end

  def has_network_template
    unless self.template.tag == 'network'
      self.errors.add(:template, 'must use the network template')
    end
  end
end
