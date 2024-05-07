class Instance < Device
  validate :has_compute_details

  def compute_device?
    true
  end

  private

  def has_compute_details
    unless details_type == 'Device::ComputeDetails'
      self.errors.add(:details_type, 'must have compute details')
    end
  end
end
