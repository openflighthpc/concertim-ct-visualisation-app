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
