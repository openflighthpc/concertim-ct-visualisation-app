class Instance < Device
  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.valid_statuses
    %w(IN_PROGRESS FAILED ACTIVE STOPPED SUSPENDED)
  end

  def self.valid_status_action_mappings
    {
      "IN_PROGRESS" => [],
      "FAILED" => %w(destroy),
      "ACTIVE" => %w(destroy off suspend),
      "STOPPED" => %w(destroy on),
      "SUSPENDED" => %w(destroy resume)
    }
  end


  ####################################
  #
  # Validations
  #
  ####################################

  validate :has_compute_details

  private

  def has_compute_details
    unless details_type == 'Device::ComputeDetails'
      self.errors.add(:details_type, 'must have compute details')
    end
  end
end
