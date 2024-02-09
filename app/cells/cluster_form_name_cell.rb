class ClusterFormNameCell < ClusterFormInputCell
  def show(cluster, form)
    @attribute = :name
    super
  end

  private

  def label_text
    'Cluster name'
  end
end
