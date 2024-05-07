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
