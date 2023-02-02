class Api::V1::Irv::RackviewPresetsController < Api::V1::Irv::BaseController

  def index
    @user = current_user
    @presets = Meca::RackviewPreset.all
  end

end
