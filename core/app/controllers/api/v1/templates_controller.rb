class Api::V1::TemplatesController < Api::V1::ApplicationController
  load_and_authorize_resource :template, :class => Ivy::Template

  def index
    @templates = @templates.rackables
    render
  end
end
