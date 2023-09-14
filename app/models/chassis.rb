class Chassis < ApplicationRecord

  self.table_name = "base_chassis"

  include Templateable
  include LiveUpdate::Chassis


  #######################
  #
  # Associations
  #
  #######################

  belongs_to :location,
             dependent: :destroy
  has_one :rack, through: :location
  has_one :device,
          foreign_key: :base_chassis_id,
          dependent: :destroy

  #######################
  #
  # Validations
  #
  #######################

  validates :name, presence: true, uniqueness: true
  validates :location_id,
            numericality: { only_integer: true }
  validates :location,
            presence: true


  ####################################
  #
  # Delegation
  #
  ####################################

  delegate :simple?, :complex?,
           to: :template, allow_nil: true

  delegate :u_depth, :u_height, :facing, :occupy_u?, :in_rack?, :has_rack?, :zero_u?, :nonrack?, :position,
           to: :location, allow_nil: true

  delegate :start_u, :end_u,
           to: :location, allow_nil: true, prefix: :rack


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
  scope :occupying_rack_u, ->{ where(location: Location.occupying_rack_u) }

  #######################
  #
  # Defaults
  #
  #######################

  def set_defaults
    self.name = assign_name if self.name.blank?
  end

  ######################################
  #
  # Hooks
  #
  ######################################
  after_initialize :set_defaults, if: Proc.new {|r| r.new_record? }

  #######################
  #
  # Instance Methods
  #
  #######################

  def assign_name
    get_default_name
  end

  #
  # compatible_with_device?
  #
  # A complex chassis will only accept a blade if it has the same
  # manufacturer and model.
  #
  def compatible_with_device?(device)
    if complex?
      # device.manufacturer == manufacturer && device.model == model
      false
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

  # get_default_name returns what should be a sensible and unique name.
  #
  # It is constructed from details taken from the chassis's template and rack
  # if available and a unique number is added.
  def get_default_name
    unique_num = Time.now.to_f
    base_name = template.nil? ? self.class.name : template.name

    name = base_name
    name += "-#{rack.name}" if has_rack?
    name += "-#{unique_num}"
    name.gsub!(' ','-')
    name.delete!("^a-zA-Z0-9\-")
    name.split("-").reject(&:blank?).join("-")

    name
  end
end
