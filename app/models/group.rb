class Group < ApplicationRecord

  ########################
  #
  # Public Instance Methods
  #
  ########################

  public

  def group_devices
    Device.where(id: member_ids)
  end

  #
  # group_chassis
  #
  # Returns complex device chassis and non-rack device chassis
  #
  def group_chassis
    raise NotImplementedError, "complex chassis and non-rack device chassis are no longer implemented"
  end

  def member_ids
    raise NotImplementedError
  end
end
