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

class ConfigureUserHandlerAndClusterBuilderWithFullUrls < ActiveRecord::Migration[7.0]
  class CloudServiceConfig < ActiveRecord::Base
  end

  def up
    add_column :cloud_service_configs, :user_handler_base_url, :string, limit: 255, null: true, default: "http://user_handler:42356"
    add_column :cloud_service_configs, :cluster_builder_base_url, :string, limit: 255, null: true, default: "http://cluster_builder:42378"

    CloudServiceConfig.reset_column_information
    config = CloudServiceConfig.first
    unless config.nil?
      url = URI(config.host_url)
      url.path = ""
      url.port = user_handler_port
      config.user_handler_base_url = url.to_s
      url.port = cluster_builder_port
      config.cluster_builder_url = url.to_s
      config.save!
    end

    change_column_null :cloud_service_configs, :user_handler_base_url, false
    change_column_null :cloud_service_configs, :cluster_builder_base_url, false

    remove_column :cloud_service_configs, :user_handler_port
    remove_column :cloud_service_configs, :cluster_builder_port
    remove_column :cloud_service_configs, :host_url
  end

  def down
    add_column :cloud_service_configs, :user_handler_port, :integer, default: 42356, null: true
    add_column :cloud_service_configs, :cluster_builder_port, :integer, default: 42378, null: true
    add_column :cloud_service_configs, :host_url, :string, limit: 255, null: true

    CloudServiceConfig.reset_column_information
    config = CloudServiceConfig.first
    unless config.nil?
      config.user_handler_port = URI(config.user_handler_base_url).port
      config.cluster_builder_port = URI(config.cluster_builder_base_url).port
      url = URI(config.user_handler_base_url)
      url.port = nil
      config.host_url = url.to_s
      config.save!
    end


    change_column_null :cloud_service_configs, :user_handler_port, false
    change_column_null :cloud_service_configs, :cluster_builder_port, false
    change_column_null :cloud_service_configs, :host_url, false

    remove_column :cloud_service_configs, :user_handler_base_url
    remove_column :cloud_service_configs, :cluster_builder_base_url
  end
end
