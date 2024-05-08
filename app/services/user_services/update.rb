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
# https://github.com/openflighthpc/concertim-ct-visualisation-app
#==============================================================================

module UserServices
  class Update
    def self.call(user, params, actor)
      new(user, actor).call(params)
    end

    def initialize(user, actor)
      @user = user
      @actor = actor
    end

    def call(params)
      updated = update(params)
      config = CloudServiceConfig.first
      changes = {password: @user.pending_foreign_password_previously_changed?, email: @user.email_previously_changed?}
      if updated && changes.values.any? && config.present?
        UserUpdateJob.perform_later(@user, changes, config)
      end
      updated
    end

    private

    def update(params)
      if @actor == @user
        self_update(params)
      elsif @actor.root?
        admin_update(params)
      else
        self_update(params)
      end
    end

    def admin_update(params)
      # An admin is performing the update, they get to update the user
      # without providing their current password.  We also, want to allow them
      # to not update the password, that is leave it blank in the form.
      if params[:password].blank?
        params.delete(:password)
        params.delete(:password_confirmation) if params[:password_confirmation].blank?
      end
      @user.update(params)
    end

    def self_update(params)
      if params.key?(:password)
        # The user is updating themselves and have provided a new password.
        # Ensure that they also provide their current password.
        @user.update_with_password(params)
      else
        # The user is updating themselves but have not provided a new
        # password.  They don't need to provide their current password.
        @user.update(params)
      end
    end
  end
end
