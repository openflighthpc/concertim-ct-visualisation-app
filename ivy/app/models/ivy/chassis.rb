module Ivy
  class Chassis < Ivy::Model

    self.table_name = "base_chassis"

    include Ivy::Concerns::Templateable


    #######################
    #
    # Constants
    #
    #######################

    # lr-tb -> left to right, top to bottom.
    VALID_POPULATION_ORDERS = %w( lr-tb lr-bt rl-tb rl-bt tb-lr bt-lr tb-rl bt-rl )


    #######################
    #
    # Associations
    #
    #######################

    # The `rack` assocation needs to be `optional: true`.  The assocation is
    # inherited by `NonRackChassis` which obviously doesn't have a rack.  If
    # `optional: true` is not set, a `NonRackChassis` would never be valid.
    # Unfortunately, it isn't possible to set this association on the
    # subclasses with appropriate `optional` settings as it is used in `has_one
    # through:` relationship in `Device`.
    #
    # This mimics the behaviour that this association had in new-legacy where
    # `belongs_to` associations where optional by default.
    #
    # A better solution may be available, but I haven't found it.
    belongs_to :rack, :class_name => "Ivy::HwRack", optional: true

    #
    # Simple chassis relationship (one of everything)
    #
    has_one :chassis_row, ->{ order(:row_number) },
      class_name: 'Ivy::ChassisRow',
      dependent: :destroy,
      foreign_key: :base_chassis_id
    has_one :slot,   through: :chassis_row
    has_one :device, through: :slot

    #
    # Non-simple chassis relationship (multiple chassis_rows, muptiple slots, multiple devices)
    #
    has_many :chassis_rows, ->{ order(:row_number) },
      class_name: 'Ivy::ChassisRow',
      :dependent => :destroy,
      :foreign_key => :base_chassis_id
    has_many :slots,   :through => :chassis_rows, source: :slot
    has_many :devices, :through => :slots

    has_one :chassis_tagged_device,
      class_name: "Ivy::Device::ChassisTaggedDevice",
      foreign_key: :base_chassis_id,
      dependent: :destroy

    #######################
    #
    # Validations
    # 
    # All validation is done here for all subclasses of chassis (using the
    # "unless" option, as you can see in the validations). This is because
    # chassis is the only STI model we have that keeps "mutating" between types
    # (a NonRackChassis becomes a RackChassis when it's moved).
    #
    #######################
    
    validates :name, presence: true, uniqueness: true
    validates :slot_population_order, inclusion: { in: VALID_POPULATION_ORDERS }, allow_blank: true

    # These are only relevant if the chassis is in a rack.
    validates :u_height, numericality: { only_integer: true, greater_than: 0 }, if: :in_rack?
    validates :rack_start_u, :rack_end_u, numericality: { only_integer: true, greater_than: 0 } , allow_blank: true, if: :in_rack? 
    validates :u_depth, numericality: { only_integer: true, greater_than: 0 }, if: :in_rack?
    validates :facing, inclusion: { in: %w( b f ) }, if: :in_rack?

    # Rack ID is not relevant for nonrack chassis.
    validates :rack_id, numericality: { only_integer: true }, unless: :nonrack?

    # Custom Validations
    validate :name_is_unique_within_device_scope
    # XXX Add validation that U is not already occupied.
    # validate :u_is_empty
    

    ####################################
    #
    # Delegation 
    #
    ####################################

    delegate :simple?,
      to: :template, allow_nil: true


    ####################################
    #
    # Hooks 
    #
    ####################################

    before_validation :calculate_rack_end_u

    #######################
    #
    # Scopes
    #
    #######################

    scope :rackable_non_showable,
      -> {
        where("base_chassis.rack_id is null and base_chassis.show_in_dcrv is not true")
          .joins(:template)
          .where("templates.rackable = ?", 1)
      }
    scope :dcrvshowable, -> { where("rack_id is null and show_in_dcrv = true") }
    scope :modified_after, ->(timestamp) { where("modified_timestamp > ?", timestamp.to_i) }
    scope :for_devices, ->(device_ids) {
      joins(:chassis_rows => {:slots => :device}).where(:devices => {:id => device_ids})
    }
    scope :for_tagged_devices, ->(device_ids) { 
      joins(:device).where(:devices => {:id => device_ids})
    }

    #######################
    #
    # Defaults
    #
    #######################

    def set_defaults
      self.slot_population_order ||= 'lr-bt'
      self.name = assign_name if self.name.blank?
    end


    #######################
    #
    # Instance Methods
    #
    #######################

    def calculate_rack_end_u
      case type
      when "RackChassis"
        self.rack_end_u = rack_start_u.nil? ? nil : rack_start_u + ( u_height || 1 ) - 1
      else 
        self.rack_end_u = rack_start_u
      end
    end

    def rack?
      self.respond_to?(:rack) && self.rack
    end

    def zero_u?
      kind_of?(Ivy::Chassis::ZeroURackChassis) || type == "ZeroURackChassis"
    end
 
    def nonrack?
      kind_of?(Ivy::Chassis::NonRackChassis) || type == "NonRackChassis"
    end

    #
    # in_rack?
    #
    # Is the chassis in a rack? Additionally, pass in a rack_id and 
    # it'll tell you if it's in THAT rack.
    #
    def in_rack?(rack_id = nil)
      if rack_id
        return !zero_u? && rack && rack.id == rack_id
      else
        return !zero_u? && rack
      end
    end

    def assign_name
      get_default_name
      # # If chassis is complex, try increment the name of the previous complex chassis
      # if !simple? 
      #   prev_chassis = Ivy::Chassis.order("id desc").select{|ch| !ch.simple?}.first
      #   if !prev_chassis.nil?
      #     new_name = prev_chassis.name.sub(/\d+$/) do |m|
      #         sprintf("%0#{$&.length}d", $&.to_i + 1)
      #     end
      #   else
      #     new_name = get_default_name
      #   end
      # else
      #   new_name = get_default_name
      # end
      # new_name 
    end


    #############################
    #
    # Private Methods
    #
    #############################
    
    private

    def name_is_unique_within_device_scope
      non_tagged_device_names = Device.untagged.pluck(:name)
      if non_tagged_device_names.include? name
        errors.add :name, "there is already a device with that name"
      end
    end

    # otherwise construct the name from the man and model and a the current second
    def get_default_name
      next_chassis_unique_num = Time.now.to_i
      manufacturer_and_model = "#{template.manufacturer}-#{template.model}" rescue template_name 
      construct_name(manufacturer_and_model, next_chassis_unique_num)
    end

    def construct_name(manu_model, unique_num)
      temp_name = manu_model
      temp_name += "-#{rack.name}" if rack?
      temp_name += "-#{unique_num}"
      temp_name.gsub!(' ','-')
      temp_name.delete!("^a-zA-Z0-9\-")
      temp_name.split("-").select{|e| e!=""}.join("-")
    end

  end
end
