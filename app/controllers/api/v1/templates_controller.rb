class Api::V1::TemplatesController < Api::V1::ApplicationController
  load_and_authorize_resource :template, :class => Template

  def index
    @templates = @templates.rackable
    render
  end

  def create
    @template = TemplateServices::Create.call(template_params.to_h)

    if @template.persisted?
      render action: :show
    else
      if @template.errors.of_kind?(:images, :blank)
        @template.errors.delete(:images, :blank)
        @template.errors.add(:images, 'No images found for template height')
      end
      render json: @template.errors.as_json, status: :unprocessable_entity
    end
  end

  def update
    if @template.update(update_params)
      render action: :show
    else
      render json: @template.errors.as_json, status: :unprocessable_entity
    end
  end

  def destroy
    recurse = ActiveModel::Type::Boolean.new.cast(params[:recurse])
    if !recurse && @template.has_devices?
      render json: {errors: "devices have been created from this template"}, status: :unprocessable_entity
    elsif @template.destroy
      render json: {}, status: :ok
    else
      render json: @template.errors.as_json, status: :unprocessable_entity
    end
  end

  private

  CREATE_ONLY_PARAMS = %w(height version schema_version tag)
  PERMITTED_PARAMS = %w(name description foreign_id vcpus ram disk) << { images: ['front', 'rear'] }
  def template_params
    params.require(:template).permit(*PERMITTED_PARAMS, *CREATE_ONLY_PARAMS)
  end

  def update_params
    params.require(:template).permit(*PERMITTED_PARAMS)
  end
end
