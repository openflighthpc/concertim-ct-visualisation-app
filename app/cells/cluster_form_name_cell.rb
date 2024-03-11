class ClusterFormNameCell < Cell::ViewModel
  def show(cluster, form)
    @record = cluster
    @form = form
    @errors = @record.errors
    @attribute = :name
    if has_clustername_parameter?
      # We don't render anything here.  Instead the value provided for the
      # 'clustername' parameter will be used.
    else
      render
    end
  end

  private

  def has_clustername_parameter?
    @record.fields.any? do |field|
      field.id == Cluster::NAME_FIELD
    end
  end

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
