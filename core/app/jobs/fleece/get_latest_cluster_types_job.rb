require 'faraday'

class Fleece::GetLatestClusterTypesJob < ApplicationJob
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

      if response.success?
        response.body.each do |type_details|
          type = Fleece::ClusterType.find_or_initialize_by(kind: type_details["id"])
          type.name = type_details["title"]
          type.description = type_details["description"]
          type.fields = order_fields(type_details["parameters"])
          type.save!
        end
      end
      Result.new(response.success?, response.reason_phrase || "Unknown error")
    rescue Faraday::Error
      Result.new(false, $!.message)
    end

    private

    def url
      @fleece_config.cluster_builder_base_url
    end

    def path
      "/cluster-types/"
    end

    def order_fields(fields)
      fields.keys.each_with_index do |field_name, index|
        fields[field_name]["order"] = index
      end
      fields
    end
  end
end
