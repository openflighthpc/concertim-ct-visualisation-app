class Fleece::ClusterTypesController < ApplicationController
  load_and_authorize_resource :cluster_type, class: Fleece::ClusterType

  def index
  end
end
