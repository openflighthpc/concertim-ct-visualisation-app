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

  # 
  # render_autocomplete_field
  #
  def render_autocomplete_field(field_id, opts = {})
    cell(:autocomplete_field).(:show, field_id, opts)
  end
end
