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

class UserPresenter < Presenter

  def authorization
    if o.root?
      "Super Admin"
    else
      "User"
    end
  end

  def status
    if o.deleted_at.nil?
      "Active"
    else
      "Pending deletion"
    end
  end

  def delete_confirmation_message
    "Are you sure you want to delete user #{o.name} (#{o.login})?"
  end

  def team_role_list
    o.team_roles.map {|team_role| "#{team_role.team.name} (#{team_role.role})" }.sort.join(", ")
  end

  def cloud_user_id_form_hint
    form_hint(:cloud_user_id)
  end

  private

  def form_hint(attribute)
    if o.send(attribute).blank?
      I18n.t("simple_form.customisations.hints.user.edit.#{attribute}.blank")
    else
      I18n.t("simple_form.customisations.hints.user.edit.#{attribute}.present")
    end
  end
end
