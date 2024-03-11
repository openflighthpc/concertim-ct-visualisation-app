class RackPresenter < Presenter
  include Costed

  delegate :instructions, :instruction,
    to: :cluster_type,
    allow_nil: true

  def creation_output
    outputs = o.creation_output.split(', ').map { |output| output.split('=') }
    Hash[outputs].tap do |h|
      if h.key?('web_access')
        h['web_access'] = @view_context.link_to(h['web_access'], h['web_access'], target: '_blank')
      end
    end
  end

  private

  def cluster_type
    @cluster_type ||=
      begin
        cluster_type_id = creation_output['concertim_cluster_type']
        ct = ClusterType.find_by(foreign_id: cluster_type_id)
        h.presenter_for(ct) if ct
      end
  end
end
