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

class RackPresenter < Presenter
  include Costed

  delegate :instructions, :instruction,
    to: :cluster_type,
    allow_nil: true

  def creation_output
    outputs = o.creation_output.split(', ').map { |output| output.split('=') }
    Hash[outputs].tap do |h|
      if h.key?('web_access')
        h['web_access'] = @view_context.link_to(h['web_access'], h['web_access'], target: '_blank')
      end
    end
  end

  private

  def cluster_type
    @cluster_type ||=
      begin
        cluster_type_id = creation_output['concertim_cluster_type']
        ct = ClusterType.find_by(foreign_id: cluster_type_id)
        h.presenter_for(ct) if ct
      end
  end
end
