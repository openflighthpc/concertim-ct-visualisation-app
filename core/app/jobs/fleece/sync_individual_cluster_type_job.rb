require 'faraday'

class Fleece::SyncIndividualClusterTypeJob < ApplicationJob
  queue_as :default

  def perform(fleece_config, cluster_type, **options)
    runner = Runner.new(
      fleece_config: fleece_config,
      cluster_type: cluster_type,
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

    def initialize(cluster_type:, **kwargs)
      @cluster_type = cluster_type
      super(**kwargs)
    end

    def call
      connection.headers["If-Modified-Since"] = latest_recorded_change
      response = connection.get(path)
      if response.status == 304
        return Result.new(true, nil)
      end

      unless response.success?
        return Result.new(false, "Unable to update cluster type: #{response.reason_phrase || "Unknown error"}")
      end

      errors = update_cluster_type(response.body)
      Result.new(errors.blank?, errors || "Unknown error")
    rescue Faraday::Error
      Result.new(false, "Unable to update cluster type: #{$!.message}")
    end

    private

    def url
      @fleece_config.cluster_builder_base_url
    end

    def path
      "/cluster-types/#{@cluster_type.foreign_id}"
    end

    def latest_recorded_change
      @cluster_type.version.httpdate
    end

    def order_fields(fields)
      return unless fields

      fields.keys.each_with_index do |field_name, index|
        fields[field_name]["order"] = index
      end
      fields
    end

    def update_cluster_type(type_details)
      @cluster_type.name = type_details["title"]
      @cluster_type.description = type_details["description"]
      @cluster_type.fields = order_fields(type_details["parameters"])
      @cluster_type.version = type_details["last_modified"]
      unless @cluster_type.save
        ["Unable to update type '#{@cluster_type.foreign_id}': #{@cluster_type.errors.full_messages.join("; ")}"]
      else
        []
      end
    end
  end
end
