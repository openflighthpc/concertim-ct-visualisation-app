class Device::DetailsPresenter < Presenter

  def is_compute_device?
    false
  end

  def additional_details
    []
  end

end
