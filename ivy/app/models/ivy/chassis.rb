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
    has_one :cluster, through: :rack

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
    validates :rack, presence: true, unless: :nonrack?

    # Custom Validations
    validate :name_is_unique_within_device_scope
    validate :target_u_is_empty, if: :in_rack?
    

    ####################################
    #
    # Delegation 
    #
    ####################################

    delegate :simple?, :complex?,
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
    scope :occupying_rack_u, ->{ where(type: :RackChassis) }

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

    # has_rack? returns true if the chassis has a rack.  Non-rack chassis do
    # not have a rack, others should.
    def has_rack?
      !rack.nil?
    end

    def zero_u?
      kind_of?(Ivy::Chassis::ZeroURackChassis) || type == "ZeroURackChassis"
    end
 
    def nonrack?
      kind_of?(Ivy::Chassis::NonRackChassis) || type == "NonRackChassis"
    end

    #
    # in_rack? returns true if the chassis is *in* a rack, i.e., it occupies a
    # rack U.  Non-rack chassis and zero-u chassis do not.
    def in_rack?
      has_rack? && !zero_u?
    end

    #
    # position returns the position of a zero-u chassis;  one of `:t`, `:m`,
    # `:b` for top, middle or bottom.
    #
    def position 
      return nil unless has_rack? && zero_u?

      case rack_start_u
      when 1
        :b
      when rack.u_height
        :t
      else 
        :m
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

    # occupy_u? returns true if the chassis occupies the given u on the given
    # facing.
    #
    # If the chassis is full depth, it occupies both facings at that U,
    # otherwise it only occupies the facing that it faces.
    def occupy_u?(rack_u, facing:nil, exclude:nil)
      return false if self.id == exclude
      return false unless in_rack?

      # If the chassis starts after the U or ends before it it doesn't occupy
      # it.
      return false if self.rack_start_u > rack_u
      return false if self.rack_end_u < rack_u

      # Otherwise the chassis occupies the U if it is full depth, or we don't
      # care about the facing, or it matches the given facing.
      if self.u_depth == self.rack.u_depth
        true
      elsif facing.nil?
        true
      elsif self.facing == facing
        true
      else
        false
      end
    end

    def update_position(params)
      self.rack_id = params[:rack_id]
      self.facing = params[:facing]
      self.rack_start_u = params[:rack_start_u]
      self.show_in_dcrv = params[:show_in_dcrv] unless params[:show_in_dcrv].nil?
      self.type = params[:type] unless params[:type].nil?
    end

    # 
    # compatible_with_device?
    # 
    # A complex chassis will only accept a blade if it has the same 
    # manufacturer and model.
    #
    def compatible_with_device?(device)
      if complex?
        device.manufacturer == manufacturer && device.model == model
      else
        false
      end
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

    # get_default_name returns what should be a sensible and unique name.
    #
    # It is constructed from details taken from the chassis's template and rack
    # if available and a unique number is added.
    def get_default_name
      unique_num = Time.now.to_f
      base_name =
        if template.nil?
          self.class.name
        else
          "#{template.manufacturer}-#{template.model}" rescue template.name 
        end

      name = base_name
      name += "-#{rack.name}" if has_rack?
      name += "-#{unique_num}"
      name.gsub!(' ','-')
      name.delete!("^a-zA-Z0-9\-")
      name.split("-").select{|e| e!=""}.join("-")

      name
    end

    def target_u_is_empty
      is_full_depth = u_depth == rack.u_depth
      facing = is_full_depth ? nil : self.facing
      return if rack.u_is_empty?(rack_start_u, exclude: self.id, facing: facing)

      errors.add(:rack_start_u, 'is occupied')
    end

  end
end
