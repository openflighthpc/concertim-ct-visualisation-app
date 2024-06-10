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

class Instance < Device
  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.valid_statuses
    %w(IN_PROGRESS FAILED ACTIVE STOPPED SUSPENDED)
  end

  def self.valid_status_action_mappings
    {
      "IN_PROGRESS" => [],
      "FAILED" => %w(destroy),
      "ACTIVE" => %w(destroy off suspend),
      "STOPPED" => %w(destroy on),
      "SUSPENDED" => %w(destroy resume)
    }
  end

  ####################################
  #
  # Validations
  #
  ####################################

  validate :has_compute_details
  validate :has_suitable_template

  ####################################
  #
  # Instance Methods
  #
  ####################################

  def hourly_compute_units
    @hourly_compute_units ||= self.template&.hourly_compute_units || 0
  end

  private

  def has_compute_details
    unless details_type == 'Device::ComputeDetails'
      self.errors.add(:details_type, 'must have compute details')
    end
  end

  def has_suitable_template
    # Tag is used to identify unique templates, i.e. network or volume
    unless template && template.tag == nil
      self.errors.add(:template, 'must use an instance template')
    end
  end
end
