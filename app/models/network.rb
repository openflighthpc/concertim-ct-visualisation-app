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

class Network < Device

  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.valid_statuses
    %w(IN_PROGRESS FAILED ACTIVE STOPPED)
  end

  def self.valid_status_action_mappings
    {
      "IN_PROGRESS" => [],
      "FAILED" => %w(destroy),
      "ACTIVE" => %w(destroy),
      "STOPPED" => %w(destroy)
    }
  end


  ####################################
  #
  # Validations
  #
  ####################################

  validate :has_network_details
  validate :has_network_template

  private

  def has_network_details
    unless details_type == 'Device::NetworkDetails'
      self.errors.add(:details_type, 'must have network details')
    end
  end

  def has_network_template
    unless self.template.tag == 'network'
      self.errors.add(:template, 'must use the network template')
    end
  end
end
