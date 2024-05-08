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

class TeamRolePresenter < Presenter
  delegate :id, :role, :team_id, :user_id, to: :o

  def requires_confirmation?(current_user)
    role == "admin" && (own_role?(current_user) || only_admin?)
  end

  def own_role?(current_user)
    current_user == o.user
  end

  def only_admin?
    @only_admin ||= TeamRole.where(team_id: team_id, role: "admin").where.not(id: id).empty?
  end

  def delete_confirmation(current_user)
    message = ""
    if only_admin?
      message = "This is the only admin user for the team. Removing them will limit access to the team.\n\n"
    end
    if own_role?(current_user)
      message << "This will remove your personal access to the team.\n\n"
    end
    message << "Do you wish to continue?"
  end

  def edit_confirmation(current_user)
    message = ""
    if only_admin?
      message = "This is the only admin user for the team. Changing their role will limit access to the team.\n\n"
    end
    if own_role?(current_user)
      message << "This will change your personal access to the team.\n\n"
    end
    message << "Do you wish to continue?"
  end
end
