module Ivy
  class HwRack < ApplicationRecord

    self.table_name = "racks"

    include Ivy::Concerns::Templateable
    include Ivy::HwRack::Occupation
    include Ivy::Concerns::LiveUpdate::HwRack


    #############################
    #
    # CONSTANTS
    #
    ############################

    DEFAULT_TEMPLATE_ID = 1
    SPACE_USED_METRIC_KEY = 'ct.capacity.rack.space_used'


    ############################
    #
    # Associations
    #
    ############################

    has_many :locations, ->{ order(start_u: :desc) },
      foreign_key: :rack_id,
      dependent: :destroy

    has_many :chassis, through: :locations
    has_many :devices, through: :chassis

    has_one :group,
      class_name: "Ivy::Group::RuleBasedGroup",
      foreign_key: :ref_text,
      primary_key: :name

    belongs_to :user, class_name: 'Uma::User'


    ############################
    #
    # Validations
    #
    ############################

    validates :name,
      presence: true,
      uniqueness: true,
      format: {
        with: /\A[a-zA-Z0-9\-\_]*\Z/,
        message: "can contain only alphanumeric characters, hyphens and underscores."
      }
    validates :u_depth, numericality: { only_integer: true, greater_than: 0 }
    validates :u_height, numericality: { only_integer: true, greater_than: 0, less_than: 73 }
    validate :u_height_greater_than_highest_occupied_u?, unless: :new_record?
    validate :rack_limit, if: :new_record?
    validate :metadata_format

    ############################
    #
    # Defaults
    #
    ############################

    def set_defaults
      self.u_depth ||= 2
      self.template_id ||= DEFAULT_TEMPLATE_ID

      # The remaining defaults take their value from that given to the last
      # rack.
      last_rack = Ivy::HwRack.all.order(:created_at).last

      self.u_height ||= last_rack.nil? ? 42 : last_rack.u_height
      self.name ||=
        if last_rack
          last_rack.name.sub(/(\d+)(\D*$)/) do |m|
            sprintf("%0#{$1.length}d%s", $1.to_i + 1, $2)
          end
        else
          "Rack-#{Ivy::HwRack.count + 1}"
        end
    end


    ####################################
    #
    # Scopes
    #
    ####################################

    scope :excluding_ids,  ->(ids) { where.not(id: ids) }


    ############################
    #
    # Class Methods
    #
    ############################

    def self.get_canvas_config
      JSON.parse(File.read(Engine.root.join("app/views/ivy/racks/_configuration.json")))
    end

    ############################
    #
    # Private Instance Methods
    #
    ############################

    private

    #
    # u_height is not allowed to be lower than space used.
    #
    def u_height_greater_than_highest_occupied_u?
      return if u_height.nil?
      if !(u_height >= highest_empty_u)
        self.errors.add(:u_height, "must be greater than the highest occupied U (minimum is therefore #{highest_empty_u}).")
      end
    end

    def rack_limit
      limit = YAML.load_file("/opt/concertim/licence-limits.yml")['rack_limit'] rescue nil
      return if limit.nil? || Ivy::HwRack.count < limit
      self.errors.add(:base, "The rack limit of #{limit} has been exceeded")
    end

    def metadata_format
      self.errors.add(:metadata, "Must be an object") unless metadata.is_a?(Hash)
    end
  end
end
