#
# Renders the flash messages at the top of the page.
#
# The functionality here has been removed from a helper and turned into a cell. It was 
# brought into a cell "as is" - I don't like the look of some of what's happening
# here but refactoring this is out of scope for the current release (I am just trying
# to mitigate the amount of stuff that gets put in helpers for now)
#
class FlashCell < Cell::ViewModel
  include HelpHelper 

  attr_reader :level, :content

  def show(context, level, text=nil, help_text=nil)
    @context    = context
    @level      = level
    @content    = generate_flash_content(level, text, help_text)
    render
  end

  private
  
  #
  # generate_flash_content
  #
  def generate_flash_content(level, text, help_text)
    "
      #{text || transform_flash(@context.flash[level])}
      #{help_text || flash_help(level)}
    "
  end

  
  #
  # flash_help
  #
  def flash_help(level)
    if level == :notice && ! @context.flash[:warn]
      help(@context.flash[:help], "Help")
    elsif level == :warn && @context.flash[:warn]
      help(@context.flash[:help], "Help")
    else
      ''
    end
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
