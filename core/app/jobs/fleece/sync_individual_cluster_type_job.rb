require 'faraday'

class Fleece::SyncIndividualClusterTypeJob < Fleece::SyncLatestClusterTypesJob
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

  class Runner < Fleece::SyncLatestClusterTypesJob::Runner

    def initialize(cluster_type:, **kwargs)
      @cluster_type = cluster_type
      super(**kwargs)
    end

    private

    def path
      "#{super}#{@cluster_type.foreign_id}"
    end

    def latest_recorded_change
      @cluster_type.version.httpdate
    end

    def sync_data(type_details)
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

    def error_description
      "Unable to update cluster type"
    end
  end
end
