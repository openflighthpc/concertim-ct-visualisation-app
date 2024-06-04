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

class Api::V1::RacksController < Api::V1::ApplicationController
  load_and_authorize_resource :rack, :class => HwRack

  def index
    @racks = @racks.map {|rack| Api::V1::RackPresenter.new(rack)}
    render
  end

  def show
    @rack = Api::V1::RackPresenter.new(@rack)
    @include_occupation_details = true
    render
  end

  def create
    @rack = HwRack.new(rack_params)

    if @rack.save
      @rack = Api::V1::RackPresenter.new(@rack)
      render action: :show
    else
      render json: @rack.errors.as_json, status: :unprocessable_entity
    end
  end

  def update
    if @rack.update(rack_params)
      @rack = Api::V1::RackPresenter.new(@rack)
      render action: :show
    else
      render json: @rack.errors.as_json, status: :unprocessable_entity
    end
  end

  #
  # DELETE /racks/1
  #
  def destroy
    if !@rack.empty? && !ActiveModel::Type::Boolean.new.cast(params[:recurse])
      render json: {errors: "rack is not empty"}, status: :unprocessable_entity
    elsif @rack.destroy
      render json: {}, status: :ok
    else
      render json: @rack.errors.as_json, status: :unprocessable_entity
    end
  end

  private

  PERMITTED_PARAMS = %w[name description u_height status cloud_created_at cost creation_output] << {metadata: {}, network_details: {}}
  def rack_params
    permitted = PERMITTED_PARAMS.dup.tap do |a|
      a << :order_id if current_user.root?
      a << :team_id  if params[:action] == 'create'
    end
    params.fetch(:rack).permit(*permitted)
  end
end
