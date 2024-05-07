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

class Api::V1::TemplatesController < Api::V1::ApplicationController
  load_and_authorize_resource :template, :class => Template

  def index
    @templates = @templates.rackable
    render
  end

  def create
    @template = TemplateServices::Create.call(template_params.to_h)

    if @template.persisted?
      render action: :show
    else
      if @template.errors.of_kind?(:images, :blank)
        @template.errors.delete(:images, :blank)
        @template.errors.add(:images, 'No images found for template height')
      end
      render json: @template.errors.as_json, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(update_params)
      render action: :show
    else
      render json: @template.errors.as_json, status: :unprocessable_entity
    end
  end

  def destroy
    recurse = ActiveModel::Type::Boolean.new.cast(params[:recurse])
    if !recurse && @template.has_devices?
      render json: {errors: "devices have been created from this template"}, status: :unprocessable_entity
    elsif @template.destroy
      render json: {}, status: :ok
    else
      render json: @template.errors.as_json, status: :unprocessable_entity
    end
  end

  private

  CREATE_ONLY_PARAMS = %w(height version schema_version tag)
  PERMITTED_PARAMS = %w(name description foreign_id vcpus ram disk) << { images: ['front', 'rear'] }
  def template_params
    params.require(:template).permit(*PERMITTED_PARAMS, *CREATE_ONLY_PARAMS)
  end

  def update_params
    params.require(:template).permit(*PERMITTED_PARAMS)
  end
end
