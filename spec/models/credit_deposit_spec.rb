require 'rails_helper'

RSpec.describe CreditDeposit, type: :model do
  subject { build(:credit_deposit) }

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is not valid without an amount" do
    subject.amount = nil
    expect(subject).to have_error(:amount, :blank)
  end

  it "is not valid if amount negative" do
    subject.amount = -1
    expect(subject).to have_error(:amount, :greater_than)
  end

  it "is not valid if amount zero" do
    subject.amount = 0
    expect(subject).to have_error(:amount, :greater_than)
  end

  it "is not valid without a team" do
    subject.team = nil
    expect(subject).to have_error(:team, :blank)
  end

  it "is not valid if team has no project id" do
    subject.team.project_id = nil
    expect(subject).to have_error(:team, "must have a project id")
  end

  it "is not valid if team has no billing account id" do
    subject.team.billing_acct_id = nil
    expect(subject).to have_error(:team, "must have a billing account id")
  end
end
