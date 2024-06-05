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

class RackPresenter < Presenter
  include Costed

  delegate :instructions, :instruction,
    to: :cluster_type,
    allow_nil: true

  def creation_output
    outputs = o.creation_output.gsub(/\b\w+=/, '').gsub(/(\w+=)|'/, '' => '', "'" => '"')
    parsed_outputs = JSON.parse("[#{outputs}]")
    results = {}
    parsed_outputs.each do |output|
      if output["output_key"] == "web_access"
        results['web_access'] = @view_context.link_to( output["output_value"], output["output_value"], target: '_blank')
      else
        results[output["output_key"]] = output["output_value"]
      end
    end
    results
  end

  private

  def cluster_type
    @cluster_type ||= h.presenter_for(o.cluster_type)
  end
end
