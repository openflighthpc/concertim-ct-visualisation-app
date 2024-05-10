class Volume < Device

  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.valid_statuses
    %w(IN_PROGRESS FAILED ACTIVE AVAILABLE)
  end

  def self.valid_status_action_mappings
    {
      "IN_PROGRESS" => [],
      "FAILED" => %w(destroy),
      "ACTIVE" => %w(detach),
      "AVAILABLE" => %w(destroy)
    }
  end

  ####################################
  #
  # Validations
  #
  ####################################

  validate :has_volume_details
  validate :has_volume_template

  private

  def has_volume_details
    unless details_type == 'Device::VolumeDetails'
      self.errors.add(:details_type, 'must have volume details')
    end
  end

  def has_volume_template
    unless self.template.tag == 'volume'
      self.errors.add(:template, 'must use the volume template')
    end
  end
end
