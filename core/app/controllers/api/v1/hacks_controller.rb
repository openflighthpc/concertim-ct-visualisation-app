class Api::V1::HacksController < Api::V1::ApplicationController
  def restart_delayed_job
    authorize! :restart, :delayed_job
    Rails.logger.info("Restarting delayed job")
    Rails.logger.info(`sudo /usr/bin/systemctl restart delayed_job 2>&1`)
    if $?.exitstatus == 0
      render json: {status: 'OK'}, status: :ok
    else
      render json: {status: 'FAILED'}, status: :internal_server_error
    end
  end
end
