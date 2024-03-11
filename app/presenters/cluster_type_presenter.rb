class ClusterTypePresenter < Presenter

  delegate :instructions, to: :o

  def instruction(id)
    o.instructions.detect do |instruction|
      instruction['id'] == id
    end
  end
end
