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

class SettingsController < ApplicationController
  def edit
    @setting = Setting.first
    authorize! :update, @setting
  end

  def edit_volume_settings
    @setting = Setting.first
    authorize! :update, @setting
  end

  def update
    @setting = Setting.first
    authorize! :update, @setting
    if @setting.update(setting_params)
      flash[:info] = "Settings successfully updated"
      redirect_back_or_to root_path
    else
      flash[:alert] = "Unable to update settings: #{@setting.errors.full_messages.join("; ")}"
      render action: :edit
    end
  end

  private

  PERMITTED_PARAMS = Setting::SETTINGS
  def setting_params
    params.fetch(:setting).permit(*PERMITTED_PARAMS)
  end
end
