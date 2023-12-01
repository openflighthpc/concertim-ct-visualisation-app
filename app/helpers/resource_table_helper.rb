#
# ResourceTableHelper
# 
# Accomodates helpers for rendering ui elements pertaining to resource tables. See
# user index page / the "resource table" cell.
#
module ResourceTableHelper

  def render_resource_table_for(collection, opts = {}, &block)
    cell(:resource_table).(:show, collection, opts, block)
  end
end
