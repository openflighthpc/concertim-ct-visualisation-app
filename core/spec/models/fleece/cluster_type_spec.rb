require 'rails_helper'

RSpec.describe Fleece::ClusterType, type: :model do
  subject { create(:fleece_cluster_type) }
  let(:fields) do
    { "clustername"=>
      {
        "type"=>"string",
        "label"=>"Cluster name",
        "order"=>0,
        "constraints"=>
      [
        {
          "length"=>{"max"=>255, "min"=>6},
          "description"=>"Cluster name must be between 6 and 255 characters"
        },
        {
          "description"=>
        "Cluster name can contain only alphanumeric characters, hyphens and underscores",
          "allowed_pattern"=>"^[a-zA-Z][a-zA-Z0-9\\-_]*$"
        }
      ],
        "description"=>"The name to give the cluster"
      }
    }
  end

  describe 'validations' do
    it "is valid with valid attributes" do
      cluster_type = described_class.new(
        name: 'Test cluster',
        description: 'A test cluster type.  It exists only for test purposes.',
        kind: 'test-cluster',
        fields: fields,
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
