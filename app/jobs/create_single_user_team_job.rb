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

class CreateSingleUserTeamJob < ApplicationJob
  queue_as :default

  def perform(user, cloud_service_config)
    team = nil
    team_role = nil

    ActiveRecord::Base.transaction do
      team = Team.new(name: "#{user.login}_team", single_user: true)
      unless team.save
        logger.info("Unable to create team for #{user.login} #{team.errors.details}")
        raise ActiveModel::ValidationError, team
      end

      team_role = TeamRole.new(team: team, user: user, role: "admin")
      unless team_role.save
        logger.info("Unable to create team role for #{user.login} #{team_role.errors.details}")
        logger.info("Rolling back creation of team #{team.name}")
        raise ActiveModel::ValidationError, team_role
      end
    end

    CreateTeamThenRoleJob.perform_later(team, team_role, cloud_service_config)
  end
end
