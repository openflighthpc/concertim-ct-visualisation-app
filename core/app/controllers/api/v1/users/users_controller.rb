class Api::V1::Users::UsersController < Api::V1::Users::BaseController

  #
  # GET /--/api/v1/users/users/can_i
  #
  # Endpoint for cancan check - this just passes the "can" request on to the
  # cancan ability checker - used to check yourself and your own abilities.
  #
  def can_i?
    # On the permissions params, this action should recieve an structure of the
    # following form
    #
    # {
    #   "permissions" => {
    #     "manage" => {"0" => "Ivy::HwRack", "1" => "Ivy::Device"},
    #     "read" => {"0" => "Ivy::Device"},
    #     "move" => {"0" => "Ivy::Device"},
    #   }
    # }

    result = {}
    params[:permissions].each do |rbac_action,rbac_resources|
      result[rbac_action] = {}
      rbac_resources.each do |_, rbac_resource|
        result[rbac_action][rbac_resource] = current_user.can?(rbac_action.to_sym, rbac_resource)
      end
    end
    render json: result
  end

end
