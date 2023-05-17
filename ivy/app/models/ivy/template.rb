module Ivy
  class Template < ApplicationRecord
    self.table_name = "templates"

    enum rackable: { rackable: 1, zerouable: 2, nonrackable: 3 }

    #######################
    #
    # Associations
    #
    #######################

    has_many :chassis, class_name: 'Ivy::Chassis',
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
end
