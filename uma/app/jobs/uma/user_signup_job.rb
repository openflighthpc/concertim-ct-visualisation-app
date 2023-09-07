require 'faraday'

class Uma::UserSignupJob < Uma::ApplicationJob
  queue_as :default

  retry_on ::Faraday::Error, wait: :exponentially_longer, attempts: 10
  retry_on ::ActiveModel::ValidationError, wait: :exponentially_longer, attempts: 10

  def perform(user, fleece_config, **options)
    runner = Runner.new(
      user: user,
      fleece_config: fleece_config,
      logger: logger,
      **options
    )
    runner.call
  end

  class Result
    include ActiveModel::API

    attr_accessor :user_id
    attr_accessor :project_id

    validates :user_id, presence: true
    validates :project_id, presence: true
  end

  class Runner < Emma::Faraday::JobRunner
    def initialize(user:, **kwargs)
      @user = user
      super(**kwargs)
    end

    def call
      response = super
      body = response.body
      result = Result.new(user_id: body["user_id"], project_id: body["project_id"])
      result.validate!
      @user.project_id = result.project_id
      @user.cloud_user_id = result.user_id
      @user.save!
    end

    private

    def url
      "#{@fleece_config.user_handler_base_url}/create_user_project"
    end

    def body
      {
        cloud_env: {
          auth_url: @fleece_config.internal_auth_url,
          user_id: @fleece_config.admin_user_id,
          password: @fleece_config.admin_foreign_password,
          project_id: @fleece_config.admin_project_id,
        },
        username: @user.login,
        password: @user.foreign_password,
        email: @user.email
      }.tap do |h|
          h[:cloud_user_id] = @user.cloud_user_id unless @user.cloud_user_id.blank?
          h[:project_id] = @user.project_id unless @user.project_id.blank?
        end
    end
  end
end
