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

  def destroy
    if UserServices::Delete.call(@user)
      flash[:info] = "Scheduled user for deletion"
      redirect_to users_path
    else
      flash[:alert] = "Unable to scheduled user for deletion"
      redirect_to users_path
    end
  end

  private

  PERMITTED_PARAMS = %w[name cloud_user_id project_id billing_acct_id]
  def user_params
    params.fetch(:user).permit(*PERMITTED_PARAMS)
  end
end
