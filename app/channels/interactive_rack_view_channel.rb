class InteractiveRackViewChannel < ApplicationCable::Channel
  def subscribed
    stream_from "irv_#{params[:user_id]}"
  end
end
