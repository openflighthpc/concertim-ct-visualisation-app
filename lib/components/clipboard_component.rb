module ClipboardComponent
  def clipboard(wrapper_options = nil)
    if options[:clipboard] == false
      has_clipboard = false
    elsif options[:clipboard] == true
      data = object.send(attribute_name)
      has_clipboard = data.present?
    else
      data = options[:clipboard]
      has_clipboard = data.present?
    end

    return nil unless has_clipboard

    additional_classes << "field_with_clipboard"
    template.button_tag("Copy",
      type: "button",
      class: "button small secondary copyToClipboard",
      data: {text: data}
    )
  end
end

SimpleForm.include_component(ClipboardComponent)
