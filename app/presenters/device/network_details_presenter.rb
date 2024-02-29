class Device::NetworkDetailsPresenter < Device::DetailsPresenter

  def additional_details
    {
      'Admin state up:': o.admin_state_up,
      'DNS domain': o.dns_domain,
      'L2 adjacency:': o.l2_adjacency,
      'MTU:': o.mtu,
      'Port security enabled:': o.port_security_enabled,
      'Shared:': o.shared,
      'QoS policy:': o.qos_policy
    }
  end

end
