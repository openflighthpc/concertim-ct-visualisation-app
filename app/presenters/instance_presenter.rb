class InstancePresenter < DevicePresenter
  delegate :vcpus, :ram, :disk,
           to: :template

end
