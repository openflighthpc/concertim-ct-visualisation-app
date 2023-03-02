class Api::V1::Irv::ThresholdsController < Api::V1::Irv::BaseController
  def index
    authorize! :index, Meca::MecaThreshold
    @thresholds = Meca::MecaThreshold.all #.to_a
    respond_to do |format|
      format.json { render :index }
    end
  end
  
end
