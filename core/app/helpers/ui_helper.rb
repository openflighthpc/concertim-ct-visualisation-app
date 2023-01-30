#
# UiHelper
#
# Presently a dumping ground for all things UI related (cells, menus...) this will eventually
# be seperated out into seperate helpers.
#
# * THIS HELPER IS ONLY TEMPORARY
# * NO METHODS IN HERE MORE THAN A FEW LINES LONG
#
module UiHelper

  extend Gem::Deprecate

  # 
  # render_autocomplete_field
  #
  def render_autocomplete_field(field_id, opts = {})
    cell(:autocomplete_field).(:show, field_id, opts)
  end


  #
  # render_lhm_actions
  #
  # The actions in the left hand menu.  Also the actions in the dropdown found
  # at the top right of the page FSR.
  #
  # XXX Consider splitting these into two separate methods.
  #
  def render_lhm_actions(title, opts = {}, &block)
    content_for :dropdown_actions do
      cell(:actions).(:show, title, block, opts.merge(is_dropdown: true))
    end
    cell(:actions).(:show, title, block, opts)
  end
end
