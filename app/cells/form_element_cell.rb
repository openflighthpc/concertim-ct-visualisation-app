class FormElementCell < Cell::ViewModel
  attr_reader :attribute, :hint

  def show(form, attribute, options={})
    @record = form.object
    @form = form
    @errors = @record.errors
    @attribute = attribute

    options.assert_valid_keys(:label, :label_html, :hint)
    @label = options.fetch(:label, true)
    @hint = options[:hint]
    @label_html = options[:label_html] || {}

    render
  end

  private

  def label
    if @label.is_a?(String)
      @label
    else
      attribute.to_s.titlecase
    end
  end

  def label?
    !!@label
  end

  def f
    @form
  end

  def has_errors?
    @errors.include?(@attribute)
  end

  def label_classes
    label_class = @label_html[:class] || ""
    label_class.tap do |classes|
      classes << " label_with_errors" if has_errors?
    end
  end

  def error_message
    @errors.messages_for(@attribute).to_sentence
  end
end
