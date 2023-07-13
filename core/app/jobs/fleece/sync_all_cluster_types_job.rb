require 'faraday'

class Fleece::SyncAllClusterTypesJob < ApplicationJob
  queue_as :default

  def perform(fleece_config, **options)
    runner = Runner.new(
      fleece_config: fleece_config,
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

  class Runner < Emma::Faraday::JobRunner

    def call
      connection.headers["If-Modified-Since"] = latest_recorded_change
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
      @fleece_config.cluster_builder_base_url
    end

    def path
      "/cluster-types/"
    end

    def latest_recorded_change
      Fleece::ClusterType.maximum(:version)&.httpdate
    end

    def order_fields(fields)
      return unless fields

      fields.keys.each_with_index do |field_name, index|
        fields[field_name]["order"] = index
      end
      fields
    end

    def sync_data(types)
      errors = []
      types.each do |type_details|
        type = Fleece::ClusterType.find_or_initialize_by(foreign_id: type_details["id"])
        type.name = type_details["title"]
        type.description = type_details["description"]
        type.fields = order_fields(type_details["parameters"])
        type.version = type_details["last_modified"]
        unless type.save
          errors << "Unable to #{type.persisted? ? "update" : "create"} type '#{type.foreign_id}': #{type.errors.full_messages.join("; ")}"
        end
      end

      Fleece::ClusterType.where.not(foreign_id: types.map { |type| type["id"] }).each do |to_remove|
        unless to_remove.destroy
          errors << "Unable to remove type '#{type.foreign_id}': #{type.errors.full_messages.join("; ")}"
        end
      end
      errors
    end

    def error_description
      "Unable to update cluster types"
    end
  end
end
