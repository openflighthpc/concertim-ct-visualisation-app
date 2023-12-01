class UsersController < ApplicationController
  load_and_authorize_resource :user

  def index
    render
  end
end
