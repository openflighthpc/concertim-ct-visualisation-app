class Volume < Device
  validate :has_volume_details
  validate :has_volume_template

  #############################
  #
  # CONSTANTS
  #
  ############################

  VALID_STATUSES = %w(IN_PROGRESS FAILED ACTIVE STOPPED SUSPENDED)
  VALID_STATUS_ACTION_MAPPINGS = {
    "IN_PROGRESS" => [],
    "FAILED" => %w(destroy),
    "ACTIVE" => %w(detach),
    "STOPPED" => %w(destroy),
    "SUSPENDED" => %w(destroy)
  }

  private

  def has_volume_details
    unless details_type == 'Device::VolumeDetails'
      self.errors.add(:details_type, 'must have volume details')
    end
  end

  def has_volume_template
    unless device.template.tag == 'volume'
      self.errors.add(:template, 'must use the volume template')
    end
  end
end
