class StatisticsController < ApplicationController
  def index
    @stats = StatisticsServices::Summary.call
  end
end
