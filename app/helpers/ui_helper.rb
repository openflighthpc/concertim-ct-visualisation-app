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
  # render_lhm_actions renders the actions for the left-hand sidebar menu.
  #
  def render_lhm_actions(title, opts = {}, &block)
    cell(:actions).(:show, title, block, opts.merge(side: true))
  end

  #
  # render_action_dropdown constructs the "Actions" dropdown in the
  # top-righthand corner.
  #
  # See `ActionsCell` and `ActionsCell::ActionBuilder` for more details.
  #
  def render_action_dropdown(title, opts={}, &block)
    content_for :dropdown_actions do
      cell(:actions).(:show, title, block, opts.merge(is_dropdown: true))
    end
  end

  def form_element(form, attribute, opts={})
    cell('form_element').(:show, form, attribute, opts)
  end
end
