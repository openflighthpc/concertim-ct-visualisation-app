object @device

attributes :id, :name, :description, :metadata, :status, :cost, :location
attributes :public_ips, :private_ips, :ssh_key,  :login_user, :volume_details

child(:template, if: @include_full_template_details) do
  extends 'api/v1/templates/show'
end

attribute :template_id, unless: @include_full_template_details
