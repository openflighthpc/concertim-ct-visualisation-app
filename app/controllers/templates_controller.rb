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

class TemplatesController < ApplicationController
  include ControllerConcerns::ResourceTable
  load_and_authorize_resource :template

  def index
    @templates = resource_table_collection(@templates.where(tag: nil))
  end

  def edit
  end

  def update
    if @template.update(template_params)
      flash[:info] = "Successfully updated template"
      redirect_to templates_path
    else
      flash[:alert] = "Unable to update template"
      render action: :edit
    end
  end

  private

  PERMITTED_PARAMS = %w[alias hourly_compute_units description]
  def template_params
    params.fetch(:template).permit(*PERMITTED_PARAMS)
  end
end
