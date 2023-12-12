class DisconnectIrvWebsocketJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    # If a user has multiple websockets (e.g. in different browsers) this will disconnect them all.
    # The front end will automatically try to reconnect - if logged out in that browser it will be
    # rejected, but if the user is still logged in it should succeed.
    ActionCable.server.remote_connections.where(current_user: User.find(user_id)).disconnect
  end
end
