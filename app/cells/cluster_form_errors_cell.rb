class ClusterFormErrorsCell < Cell::ViewModel
  def show(cluster)
    @cluster = cluster
    render
  end

  private

  def has_errors?
    error_count > 0
  end

  def error_count
    if @cluster.errors.any?
      # If the cluster has any errors set against it, it is expected that these
      # will contain any field errors too.
      @cluster.errors.count

    elsif @cluster.fields.any? { |f| !f.errors.empty? }
      # If the cluster does not have any errors, it is still possible that the
      # fields do.  These can be set from the cluster builder response.
      @cluster.fields
        .select { |f| !f.errors.empty? }
        .map { |f| f.errors.count }
        .sum
    else
      0
    end
  end
end
