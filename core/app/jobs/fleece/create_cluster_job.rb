require 'faraday'

class Fleece::CreateClusterJob < ApplicationJob
  queue_as :default

  def perform(cluster, fleece_config, user, **options)
    runner = Runner.new(
      cluster: cluster,
      user: user,
      fleece_config: fleece_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    attr_reader :status_code

    def initialize(success, error_message, status_code=nil, non_field_error=nil)
      @success = !!success
      @error_message = error_message
      @status_code = status_code
      @non_field_error = non_field_error
    end

    def success?
      @success
    end

    def non_field_error?
      success? ? nil : !!@non_field_error
    end

    def error_message
      success? ? nil : @error_message
    end
  end

  class Runner < Emma::Faraday::JobRunner
    def initialize(cluster:, user:, **kwargs)
      @cluster = cluster
      @user = user
      super(**kwargs)
    end

    def call
      response = connection.post(path, body)
      Result.new(response.success?, response.reason_phrase || "Unknown error", response.status)

    rescue Faraday::BadRequestError
      errors = Emma::Jsonapi::Errors.parse($!.response_body)
      non_field_error = merge_errors_to_fields(errors)
      error_message = errors.full_details.to_sentence
      Result.new(false, error_message, $!.response[:status], non_field_error)

    rescue Faraday::Error
      status_code = $!.response[:status] rescue 0
      Result.new(false, $!.message, status_code)
    end

    private

    def url
      @fleece_config.cluster_builder_base_url
    end

    def path
      "/clusters/"
    end

    def body
      {
        cloud_env: cloud_env_details,
        cluster: cluster_details
      }
    end

    def cluster_details
      {
        cluster_type_id: @cluster.type_id,
        name: @cluster.name,
        parameters: @cluster.field_values
      }
    end

    def cloud_env_details
      {
        auth_url: @fleece_config.internal_auth_url,
        user_id: @user.cloud_user_id.gsub(/-/, ''),
        password: @user.foreign_password,
        project_id: @user.project_id
      }
    end

    # For any errors that can be mapped to a cluster field, add an error on
    # that field.  Return true if there are any errors that cannot be mapped to
    # a cluster field.
    def merge_errors_to_fields(errors)
      non_field_error_found = false
      field_pointers = @cluster.fields.map { |f| ["/cluster/parameters/#{f.id}", f] }
      errors.each do |error|
        is_field_error = false
        field_pointers.each do |fp|
          if error.match?(fp.first)
            @cluster.add_field_error(fp.last, error.detail)
            is_field_error = true
            break
          end
        end
        non_field_error_found = true unless is_field_error
      end
      non_field_error_found
    end
  end
end
