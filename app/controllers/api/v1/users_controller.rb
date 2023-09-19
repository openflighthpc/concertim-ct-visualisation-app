class Api::V1::UsersController < Api::V1::ApplicationController
  load_and_authorize_resource :user, :class => User, except: [:current, :can_i?]

  def index
    @users = @users.map {|user| Api::V1::UserPresenter.new(user)}
    render
  end

  def show
    @user = Api::V1::UserPresenter.new(@user)
    render
  end

  def current
    authorize! :read, current_user
    @user = Api::V1::UserPresenter.new(current_user)
    render action: :show
  end

  def update
    if @user.update(user_params)
      @user = Api::V1::UserPresenter.new(@user)
      render action: :show
    else
      render json: @user.errors.as_json, status: :unprocessable_entity
    end
  end

  #
  # GET /api/v1/users/can_i
  #
  # Endpoint for cancan check - this just passes the "can" request on to the
  # cancan ability checker - used to check yourself and your own abilities.
  #
  def can_i?
    # On the permissions params, this action should receive a structure of the
    # following form
    #
    # {
    #   "permissions" => {
    #     "manage" => {"0" => "HwRack", "1" => "Device"},
    #     "read" => {"0" => "Device"},
    #     "move" => {"0" => "Device"},
    #   }
    # }

    result = {}
    params[:permissions].each do |rbac_action,rbac_resources|
      result[rbac_action] = {}
      rbac_resources.each do |_, rbac_resource|
        if rbac_resource == "all"
          result[rbac_action][rbac_resource] = current_user.can?(rbac_action.to_sym, :all)
        elsif rbac_resource.safe_constantize
          result[rbac_action][rbac_resource] = current_user.can?(rbac_action.to_sym, rbac_resource.safe_constantize)
        else
          result[rbac_action][rbac_resource] = false
        end
      end
    end
    render json: result
  end

  private

  def user_params
    permitted_params = current_user.root? ? [:project_id, :cloud_user_id, :cost, :billing_period_start, :billing_period_end] : []
    params.require(:user).permit(*permitted_params)
  end
end
