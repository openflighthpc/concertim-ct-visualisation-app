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

class BroadcastRackChangeJob < ApplicationJob
  queue_as :default

  def perform(rack_id, team_id, action)
    if action == "deleted"
      msg = { action: action, rack: {id: rack_id}}
    else
      msg = rack_content(rack_id, action)
    end
    user_roles = TeamRole.where(team_id: team_id)
    role_mapping = user_roles.pluck(:user_id, :role).to_h
    User.where(root: true).or(User.where(id: role_mapping.keys)).each do |user|
      unless action == "deleted"
        role = user.root? ? "superAdmin" : role_mapping[user.id]
        msg[:rack][:teamRole] = role
      end
      InteractiveRackViewChannel.broadcast_to(user, msg)
    end
  end

  def rack_content(rack_id, action)
    { action: action, rack: Irv::HwRackServices::Show.call(rack_id) }
  end
end
