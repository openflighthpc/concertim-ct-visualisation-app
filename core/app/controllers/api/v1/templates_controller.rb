class Api::V1::TemplatesController < Api::V1::ApplicationController
  load_and_authorize_resource :template, :class => Ivy::Template

  def index
    @templates = @templates.rackables
    render
  end

  def create
    @template = Ivy::TemplateServices::Create.call(template_params.to_h)

    if @template.persisted?
      render action: :show
    else
      render json: @template.errors.details, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(update_params)
      render action: :show
    else
      render json: @template.errors.details, status: :unprocessable_entity
    end
  end

  def destroy
    recurse = ActiveModel::Type::Boolean.new.cast(params[:recurse])
    if !recurse && @template.has_devices?
      render json: {errors: "devices have been created from this template"}, status: :unprocessable_entity
    elsif @template.destroy
      render json: {}, status: :ok
    else
      render json: @template.errors.details, status: :unprocessable_entity
    end
  end

  private

  PERMITTED_PARAMS = %w(name description height version schema_version)
  def template_params
    params.require(:template).permit(*PERMITTED_PARAMS)
  end

  def update_params
    params.require(:template).permit(:name, :description)
  end
end
