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

class StatisticsController < ApplicationController
  def index
    authorize! :read, :statistics
    @concertim_stats = StatisticsServices::Summary.call
    @cloud_stats = {}
    @cloud_service_config = CloudServiceConfig.first
    if @cloud_service_config
      cloud_stats = GetCloudStatsJob.perform_now(@cloud_service_config)
      if cloud_stats.success?
        @cloud_stats = {totals: cloud_stats.stats}
      else
        flash[:alert] = cloud_stats.error_message
      end
    else
      flash[:alert] = "Unable to retrieve cloud stats - cloud configuration not set"
    end
  end
end
