class ClusterFormNameCell < Cell::ViewModel
  def show(cluster, form)
    @record = cluster
    @form = form
    @errors = @record.errors
    @attribute = :name
    render
  end

  private

  def label_text
    'Cluster name'
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
