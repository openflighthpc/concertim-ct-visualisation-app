class Device::ComputeDetailsPresenter < Device::DetailsPresenter

  delegate :public_ips, :private_ips, :login_user, :ssh_key, :volume_details, to: :o

  def is_compute_device?
    true
  end

end
