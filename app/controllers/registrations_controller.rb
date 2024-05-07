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

# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  def create
    super
    if @user.persisted?
      config = CloudServiceConfig.first
      if config.present?
        UserSignupJob.perform_later(@user, config)
      else
        Rails.logger.info("Unable to schedule UserSignupJob: Config has not been created")
      end
    end
  end

  protected

  def update_resource(resource, params)
    UserServices::Update.call(resource, params, current_user)
  end

  def account_update_params
    super.tap do |params|
      if params[:password].blank? && params[:password_confirmation].blank?
        params.delete :password
        params.delete :password_confirmation
        params.delete :current_password
      end
    end
  end

  # Use the application root path not the engine root path.
  def signed_in_root_path(resource)
    Rails.application.routes.url_helpers.root_path
  end

  private

  def configure_permitted_parameters
    update_attrs = [:name]
    devise_parameter_sanitizer.permit :account_update, keys: update_attrs

    sign_up_attrs = [:login, :email] + update_attrs
    devise_parameter_sanitizer.permit :sign_up, keys: sign_up_attrs
  end
end
