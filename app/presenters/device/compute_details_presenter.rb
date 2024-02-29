class Device::ComputeDetailsPresenter < Device::DetailsPresenter

  delegate :public_ips, :private_ips, :login_user, :ssh_key, :volume_details, to: :o

  def additional_details
    [].tap do |d|
      if has_login_details?
        d << [
          'Access details:',
          {
            'Login user:': login_user || 'Unknown',
            'Public IPs:': public_ips,
            'Private IPs:': private_ips,
            'SSH key:': ssh_key || 'Unknown'
          }
        ]
      end

      if has_volume_details?
        d << [
          'Volume details:', volume_details
        ]
      end

    end
  end


  private

  def has_login_details?
    public_ips || private_ips || ssh_key || login_user
  end

  def has_volume_details?
    !volume_details.empty?
  end

end
