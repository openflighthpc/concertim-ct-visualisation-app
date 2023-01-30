class Api::V1::Groups::GroupsController < Api::V1::Groups::BaseController

  def index
    @groups = group_loader.sort do |i,j|
      i[:name].downcase <=> j[:name].downcase
    end

    determine_renderer_for('index')
  end
  
  private

  def group_loader
    case params[:group_filter]
    when 'excluding_system_virtual_groups'
      Ivy::Group.excluding_system_virtual_groups
    when 'excluding_system_virtual_servers_in_hosts_groups'
      Ivy::Group.excluding_system_virtual_servers_in_hosts_groups
    when 'excluding_system_non_physical_device_groups'
      Ivy::Group.excluding_system_non_physical_device_groups
    else
      Ivy::Group.all
    end
  end

end
