class Api::V1::HacksController < Api::V1::ApplicationController
  def restart_delayed_job
    authorize! :restart, :delayed_job
    `/usr/bin/systemctl restart delayed_job`
    render json: {status: 'OK'}, status: :ok
  end
end
