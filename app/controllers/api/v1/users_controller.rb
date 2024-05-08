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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

class Api::V1::UsersController < Api::V1::ApplicationController
  load_and_authorize_resource :user, :class => User, except: [:current, :permissions]

  def index
    @users = @users.map {|user| Api::V1::UserPresenter.new(user)}
    render
  end

  def show
    @user = Api::V1::UserPresenter.new(@user)
    render
  end

  def current
    authorize! :read, current_user
    @user = Api::V1::UserPresenter.new(current_user)
    render action: :show
  end

  def update
    if UserServices::Update.call(@user, user_params, current_user)
      @user = Api::V1::UserPresenter.new(@user)
      render action: :show
    else
      render json: @user.errors.as_json, status: :unprocessable_entity
    end
  end

  def destroy
    if !@user.racks.empty? && !ActiveModel::Type::Boolean.new.cast(params[:recurse])
      error = {status: "422", title: "Unprocessable Content", description: "Cannot delete user as they have active racks"}
      render json: {errors: [error]}, status: :unprocessable_entity
    elsif UserServices::Delete.call(@user)
      render json: {}, status: :ok
    else
      render json: @user.errors.as_json, status: :unprocessable_entity
    end
  end

  #
  # GET /api/v1/users/permissions
  #
  # Endpoint for specifying what permissions each team role/ being root provides.
  # This is based on the assumption that such permissions are based purely
  # on team role for the given object (or being root).
  #
  def permissions
    admins = %w(superAdmin admin)
    all = admins + ["member"]
    result = {
      manage: {
        racks: admins, devices: admins, chassis: admins
      },
      move: {
        racks: [], devices: admins, chassis: admins
      },
      view: {
        racks: all, devices: all, chassis: all
      }
    }
    render json: result
  end

  private

  def user_params
    permitted_params =
      if current_user.root?
        [:project_id, :cloud_user_id, :cost, :credits, :billing_acct_id, :billing_period_start, :billing_period_end]
      else
        []
      end
    params.require(:user).permit(*permitted_params)
  end
end
