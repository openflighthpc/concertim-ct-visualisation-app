class Api::V1::Irv::ThresholdsController < Api::V1::Irv::BaseController
  def index
    @thresholds = Meca::MecaThreshold.all #.to_a
    respond_to do |format|
      format.json { render :index }
    end
  end
  
end
