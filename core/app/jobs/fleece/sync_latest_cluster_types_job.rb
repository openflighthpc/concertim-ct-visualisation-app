require 'faraday'

class Fleece::SyncLatestClusterTypesJob < ApplicationJob
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
      response = connection.get(path)
      unless response.success?
        return Result.new(false, "Unable to update cluster types: #{response.reason_phrase || "Unknown error"}")
      end

      errors = update_cluster_types(response.body)
      Result.new(errors.empty?, errors.join("<br>") || "Unknown error")
    rescue Faraday::Error
      Result.new(false, "Unable to update cluster types: #{$!.message}")
    end

    private

    def url
      @fleece_config.cluster_builder_base_url
    end

    def path
      "/cluster-types/"
    end

    def order_fields(fields)
      return unless fields

      fields.keys.each_with_index do |field_name, index|
        fields[field_name]["order"] = index
      end
      fields
    end

    def update_cluster_types(types)
      errors = []
      types.each do |type_details|
        type = Fleece::ClusterType.find_or_initialize_by(foreign_id: type_details["id"])
        type.name = type_details["title"]
        type.description = type_details["description"]
        type.fields = order_fields(type_details["parameters"])
        unless type.save
          errors << "Unable to #{type.persisted? ? "update" : "create"} type '#{type.foreign_id}': #{type.errors.full_messages.join("; ")}"
        end
      end
      errors
    end
  end
end
