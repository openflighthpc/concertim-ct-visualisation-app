class UsersController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :user

  def index
    @users = resource_table_collection(@users)
    render
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:info] = "Successfully updated user"
      redirect_to users_path
    else
      flash[:alert] = "Unable to update user"
      render action: :edit
    end
  end

  # A placeholder action for developing the resource table used on the
  # users/index page.  This should be removed once we have real actions to go
  # in the actions dropdown.
  def placeholder
    user = User.find(params[:id])
    flash[:info] = "placeholder action: found user: #{user.login}"
    redirect_back_or_to root_path
  end

  private

  PERMITTED_PARAMS = %w[name cloud_user_id project_id billing_acct_id]
  def user_params
    params.fetch(:user).permit(*PERMITTED_PARAMS)
  end
end
