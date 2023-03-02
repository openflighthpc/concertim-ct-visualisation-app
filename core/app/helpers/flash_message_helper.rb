module FlashMessageHelper

  #
  # flash_box
  #
  # Renders a flash box at the appropriate level (see core/app/cells/flash_cell)
  #
  def flash_box(level, text=nil, help_text=nil)
    cell(:flash).(:show, self, level, text, help_text)
  end

end
