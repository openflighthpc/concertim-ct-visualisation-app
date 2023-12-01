class UsersController < ApplicationController
  load_and_authorize_resource :user

  def index
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
