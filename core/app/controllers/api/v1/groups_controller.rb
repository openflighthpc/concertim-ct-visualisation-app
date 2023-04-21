class Api::V1::GroupsController < Api::V1::ApplicationController
  load_and_authorize_resource :group, :class => Ivy::Group

  before_action :check_params, :only=>[:show]

  def index
    @groups = @groups.sort do |i,j|
      i[:name].downcase <=> j[:name].downcase
    end

    determine_renderer_for('index')
  end

  def show
    determine_renderer_for('show')
  end

  private

  def check_params
    error_for('Group') if params[:id].nil? || params[:id].empty?
  end

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
