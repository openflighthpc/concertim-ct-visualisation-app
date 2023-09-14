#
# Mixin for methods pertaining to authorization.
#
module Authorization
  extend ActiveSupport::Concern

  included do
    rescue_from CanCan::AccessDenied do |exception|
      Rails.logger.info "User #{current_user.id} does not have permission to #{exception.action} #{exception.subject}"
      @offending_action = exception.action
      @offending_subject = exception.subject.name rescue exception.subject

      respond_to do |format|
        format.html { render "errors/403", status: 403 }
        format.json do
          error = {
            status: "403",
            title: "Not Authorized",
            detail: "Requires ability to #{@offending_action} #{@offending_subject}"
          }
          render json: {errors: [error]}, status: 403
        end
      end
    end
  end
end
