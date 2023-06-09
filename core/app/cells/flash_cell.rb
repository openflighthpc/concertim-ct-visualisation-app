#
# Renders the flash messages at the top of the page.
#
# The functionality here has been removed from a helper and turned into a cell. It was 
# brought into a cell "as is" - I don't like the look of some of what's happening
# here but refactoring this is out of scope for the current release (I am just trying
# to mitigate the amount of stuff that gets put in helpers for now)
#
class FlashCell < Cell::ViewModel
  # LEVELS = %i(success secondary notice info warning alert)
  LEVELS = %i(success notice info alert)

  attr_reader :level, :content

  def show(context, level, text=nil, help_text=nil)
    check_level(level) if Rails.env.development?
    @context    = context
    @level      = level
    @content    = generate_flash_content(level, text, help_text)
    render
  end

  private

  def check_level(level)
    unless LEVELS.include?(level.to_sym)
      Rails.logger.warn("Unsupported flash level #{level.inspect}: should be one of #{LEVELS.inspect}")
    end
  end

  #
  # generate_flash_content
  #
  def generate_flash_content(level, text, help_text)
    "
      #{text || transform_flash(@context.flash[level])}
      #{help_text}
    "
  end

  #
  # transform_flash
  #
  # Replace any special phrases in flash with view specific mark-up
  def transform_flash(msg)
    return msg if @context.flash.now[:gsubs].nil?
    @context.flash.now[:gsubs].each { |k,v| msg = msg.gsub(k,v) }
    msg
  end

end
