module TitleHelper

  #
  # set_title sets the content for the :page_title page section, which is used
  # both as a heading (h2) on all pages as well as the actual <title> meta tag.
  #
  def set_title(title)
    content_for :title do
      title
    end
  end

  def title_css_classes
    css_classes = []
    icon = @icon_override
    if active_navigation_item && active_navigation_item.options.nil?
      icon = controller_name.singularize
    else
      curr_item = active_navigation_item
      if curr_item && !curr_item.options.nil? && !curr_item.options[:icon].blank?
        icon = curr_item.options[:icon]
      else
        level2_item = active_navigation_item(:level => 2)
        icon = (level2_item ? level2_item.options[:icon] || inferred_heading : inferred_heading)
      end
    end
    css_classes << "icon-#{icon.to_s.parameterize}" unless icon.blank?
    css_classes << (active_navigation_item_key || inferred_heading)

    css_classes.join(' ')
  end

  def inferred_heading
    "#{params[:controller].split('/').last}_#{params[:action]}"
  end

  #
  # sanitize_title removes anchors and other tags from a string (so they can be
  # used for page titles)
  #
  # XXX Does rails provide a better mechanism for this than using regexes.
  #
  def sanitize_title(title)
    title.gsub!(/<\/?a[^>]*>/, "")
    title.gsub!(/<\/?[^>]*>/, '"')
    raw title
  end

end
