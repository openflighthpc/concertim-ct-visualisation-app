require 'rails_helper'

RSpec.describe KeyPair, type: :model do
  let(:user) { create(:user, :with_openstack_account) }
  subject { build(:key_pair, user: user, fingerprint: "abc") }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without a name" do
    subject.name = nil
    expect(subject).to have_error(:name, :blank)
  end

  it "is not valid without a user" do
    subject.user = nil
    expect(subject).to have_error(:user, :blank)
  end

  it "is not valid with a blank fingerprint" do
    subject.fingerprint = nil
    expect(subject).to have_error(:fingerprint, :blank)
  end
end
