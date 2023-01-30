class Api::V1::Groups::BaseController < Api::V1::ApplicationController

  private

  def determine_renderer_for(action)
    group_for = params.delete(:group_for)

    case group_for
    when 'irv'
      puts "rendering irv one"
      render "irv_#{action}"
    when 'dcpv'
      puts "rendering dcpv one"
      render "dcpv_#{action}"
    else
      puts "rendering groups one"
      render "#{action}" 
    end
  end

end
