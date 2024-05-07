#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

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
    if UserServices::Update.call(@user, user_params, current_user)
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
      flash[:alert] = "Unable to schedule user for deletion"
      redirect_to users_path
    end
  end

  private

  PERMITTED_PARAMS = %w[name cloud_user_id password password_confirmation]
  def user_params
    params.fetch(:user).permit(*PERMITTED_PARAMS)
  end
end
