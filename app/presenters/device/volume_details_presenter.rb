class Device::VolumeDetailsPresenter < Device::DetailsPresenter

  def additional_details
    {
      'Availability zone:': o.availability_zone,
      'Bootable:': o.bootable,
      'Encrypted:': o.encrypted,
      'Read-only:': o.read_only,
      'Size (GB):': o.size,
      'Volume type:': o.volume_type
    }
  end

end
