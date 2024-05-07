#==============================================================================
# Copyright (C) 2024-present Alces Flight Ltd.
#
# This file is part of Concertim Visualisation App.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Concertim Visualisation App is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Concertim Visualisation App. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Concertim Visualisation App, please visit:
# https://github.com/openflighthpc/ct-visualisation-app
#==============================================================================

#
# Mixin for methods pertaining to authorization.
#
module ControllerConcerns
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
end
