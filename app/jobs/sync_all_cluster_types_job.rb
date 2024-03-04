require 'faraday'

class SyncAllClusterTypesJob < ApplicationJob
  queue_as :default

  def perform(cloud_service_config, use_cache=true, **options)
    runner = Runner.new(
      cloud_service_config: cloud_service_config,
      use_cache: use_cache,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    def initialize(success, error_message)
      @success = !!success
      @error_message = error_message
    end

    def success?
      @success
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < HttpRequests::Faraday::JobRunner

    def initialize(use_cache:true, **kwargs)
      @use_cache = use_cache
      super(**kwargs)
    end

    def call
      connection.headers["If-Modified-Since"] = latest_recorded_change if @use_cache
      response = connection.get(path)
      if response.status == 304
        return Result.new(true, nil)
      end

      unless response.success?
        return Result.new(false, "#{error_description}: #{response.reason_phrase || "Unknown error"}")
      end

      errors = sync_data(response.body)
      Result.new(errors.empty?, errors.join("<br>") || "Unknown error")
    rescue Faraday::Error
      Result.new(false, "#{error_description}: #{$!.message}")
    end

    private

    def url
      @cloud_service_config.cluster_builder_base_url
    end

    def path
      "/cluster-types/"
    end

    def latest_recorded_change
      ClusterType.maximum(:version)&.httpdate
    end

    def ordered_fields(fields)
      return unless fields

      fields.keys.each_with_index do |field_name, index|
        fields[field_name]["order"] = index
      end
      fields
    end

    def sync_data(types)
      errors = []
      types.each do |type_details|
        type = ClusterType.find_or_initialize_by(foreign_id: type_details["id"])
        type.name = type_details["title"]
        type.description = type_details["description"]
        type.fields = ordered_fields(type_details["parameters"])
        type.field_groups = type_details["parameter_groups"]
        type.version = type_details["last_modified"]
        type.order = type_details["order"]
        type.logo_url = type_details["logo_url"]
        unless type.save
          errors << "Unable to #{type.persisted? ? "update" : "create"} type '#{type.descriptive_name}': #{type.errors.full_messages.join("; ")}"
        end
      end

      ClusterType.where.not(foreign_id: types.map { |type| type["id"] }).each do |to_remove|
        unless to_remove.destroy
          errors << "Unable to remove type '#{to_remove.descriptive_name}': #{to_remove.errors.full_messages.join("; ")}"
        end
      end
      errors
    end

    def error_description
      "Unable to update cluster types"
    end
  end
end
