require 'rails_helper'

RSpec.describe Cluster, type: :model do
  let(:cluster_params) { { "clustername" => "testing"} }
  subject { build(:cluster, cluster_params: cluster_params) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without a name" do
    subject.name = nil
    expect(subject).to have_error(:name, :blank)
  end

  it "is not valid without a cluster type" do
    subject.cluster_type = nil
    expect(subject).to have_error(:cluster_type, :blank)
  end

  it "is not valid with a blank param" do
    cluster_params["clustername"] = nil
    expect(subject).to have_error("Cluster name", "can't be blank")
  end

  it "is not valid without a team" do
    subject.team = nil
    expect(subject).to have_error(:team, :blank)
  end

  it "is not valid if team has insufficient credits" do
    subject.team.update(credits: 0)
    expect(subject).to have_error(:team, "Has insufficient credits to launch a cluster")
  end
end
