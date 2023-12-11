class UsersController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :user

  def index
    @users = resource_table_collection(@users)
    render
  end

  # A placeholder action for developing the resource table used on the
  # users/index page.  This should be removed once we have real actions to go
  # in the actions dropdown.
  def placeholder
    user = User.find(params[:id])
    flash[:info] = "placeholder action: found user: #{user.login}"
    redirect_back_or_to root_path
  end
end
