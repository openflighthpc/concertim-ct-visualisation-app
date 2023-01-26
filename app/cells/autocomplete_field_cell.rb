#
# AutocompleteFieldCell
#
# For displaying autocomplete dropdowns that the user can type into, based
# on autocomplete data downloaded from a remote source. 
#
class AutocompleteFieldCell < Cell::ViewModel

  attr_reader :field

  def show(field_id, options={})
    @field = AutocompleteField.new(field_id, options)
    render
  end

  private

  class AutocompleteField

    attr_reader :field_id, :url, :id, :name, :classes, :tabindex, :onfocus, :is_remote_url, :data_bind, :value, :style, :button_style, :required
    
    def initialize(field_id, options)
      @field_id        = field_id
      @url             = options.delete(:url) or raise "url required"
      @id              = options.delete(:no_field_id_prepend) ? field_id : "#{field_id}_name"
      @name            = options.delete(:name) || "#{field_id}_name"
      @classes         = options.delete(:classes)
      @style           = options.delete(:style)
      @button_style    = options.delete(:button_style)
      @tabindex        = options.delete(:tabindex) || 1
  		@onfocus         = options.delete(:onfocus)
  		@is_remote_url   = options.delete(:is_remote_url) || false
  		@data_bind       = options.delete(:databind)
      @value           = options.delete(:value)
      @required        = options.delete(:required) || false
    end

    def containing_div_id
      "#{field_id}_auto_complete_box"
    end

    def url_field_id
      "#{field_id}_url"
    end

    def button_field_id
      "#{field_id}_button"    
    end
  end
end
