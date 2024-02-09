# Purely a parent class. @attribute must be set in the
# show method of the subclass
class ClusterFormInputCell < Cell::ViewModel
  def show(cluster, form)
    raise NotImplementedError unless @attribute
    @record = cluster
    @form = form
    @errors = @record.errors
    render
  end

  private

  def label_text
    raise NotImplementedError
  end

  def f
    @form
  end

  def attribute
    @attribute
  end

  def has_errors?
    @errors.include?(@attribute)
  end

  def label_classes
    "required_field".tap do |classes|
      classes << " label_with_errors" if has_errors?
    end
  end

  def error_message
    @errors.messages_for(@attribute).to_sentence
  end
end
