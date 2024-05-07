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

class Template < ApplicationRecord
  enum rackable: { rackable: 1, zerouable: 2, nonrackable: 3 }

  #######################
  #
  # Associations
  #
  #######################

  has_many :chassis,
           dependent: :destroy


  ############################
  #
  # Validations
  #
  ############################

  validates :name,
            presence: true,
            uniqueness: true,
            length: { maximum: 255 }
  validates :height,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :depth,
            presence: true,
            numericality: { only_integer: true, in: 1..2 }
  validates :version,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :template_type,
            presence: true,
            inclusion: { in: %w[Device HwRack] }
  validates :rackable,
            presence: true
  validates :simple,
            inclusion: { in: [true, false] }
  validates :description,
            length: { maximum: 255 }
  validates :images,
            presence: true
  validates :padding_left,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :padding_bottom,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :padding_right,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :padding_top,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :model,
            length: { maximum: 255 }
  validates :rack_repeat_ratio,
            length: { maximum: 255 }

  # The following attributes have different validations depending on whether
  # this is a template for a rack or a device.
  validates :rows,
            numericality: { only_integer: true },
            inclusion: { in: [1] },
            unless: ->{ template_type == 'HwRack' }
  validates :columns,
            numericality: { only_integer: true },
            inclusion: { in: [1] },
            unless: ->{ template_type == 'HwRack' }
  validates :rackable,
            inclusion: { in: ['rackable'] },
            unless: ->{ template_type == 'HwRack' }

  validates :rows,
            absence: true,
            if: ->{ template_type == 'HwRack' }
  validates :columns,
            absence: true,
            if: ->{ template_type == 'HwRack' }
  validates :rackable,
            inclusion: { in: ['nonrackable'] },
            if: ->{ template_type == 'HwRack' }

  validates :foreign_id,
            length: { maximum: 255 },
            allow_nil: true
  validates :vcpus,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :ram,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :disk,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true

  validates :tag,
            uniqueness: true,
            if: :tag

  ####################################
  #
  # Class Methods
  #
  ####################################

  def self.default_rack_template
    find_by_tag('rack')
  end

  #######################
  #
  # Instance Methods
  #
  #######################

  def complex?
    !simple?
  end

  # Return true if there are any devices that have been created from this
  # template.
  def has_devices?
    chassis.count > 0
  end
end
