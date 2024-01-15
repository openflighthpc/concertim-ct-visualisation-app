class SettingsController < ApplicationController
  def edit
    @setting = Setting.first
    authorize! :update, @setting
  end

  def update
    @setting = Setting.first
    authorize! :update, @setting
    if @setting.update(setting_params)
      flash[:info] = "Settings successfully updated"
      redirect_to root_path
    else
      flash[:alert] = "Unable to update settings"
      render action: :edit
    end
  end

  private

  PERMITTED_PARAMS = Setting::SETTINGS
  def setting_params
    params.fetch(:setting).permit(*PERMITTED_PARAMS)
  end
end
