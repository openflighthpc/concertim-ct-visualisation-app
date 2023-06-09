require 'rails_helper'

RSpec.describe Fleece::ClusterType, type: :model do
  subject { create(:fleece_cluster_type) }

  describe 'validations' do
    it "is valid with valid attributes" do
      cluster_type = described_class.new(
        name: 'Test cluster',
        description: 'A test cluster type.  It exists only for test purposes.',
        kind: 'test-cluster',
        nodes: 1,
      )
      expect(cluster_type).to be_valid
    end

    it "has a valid factor" do
      cluster_type = described_class.new(attributes_for(:fleece_cluster_type))
      expect(cluster_type).to be_valid
    end

    it "is not valid without a name" do
      subject.name = nil
      expect(subject).to have_error(:name, :blank)
    end

    it "is not valid without a description" do
      subject.description = nil
      expect(subject).to have_error(:description, :blank)
    end

    describe "kind" do
      it "is not valid without a kind" do
        subject.kind = nil
        expect(subject).to have_error(:kind, :blank)
      end

      it "must have a unique kind" do
        new_cluster_type = build(:fleece_cluster_type, kind: subject.kind)
        expect(new_cluster_type).to have_error(:kind, :taken)
      end
    end
  end
end
