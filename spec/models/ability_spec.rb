require 'rails_helper'

RSpec.describe Ability, type: :model do
  let!(:user) { create(:user) }

  describe "#enough_credits_to_create_cluster?" do
    it "is false if zero" do
      user.credits = 0
      expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
    end

    it "is false if below set requirement" do
      Rails.application.config.cluster_credit_requirement = 10
      user.credits = 9
      expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
    end

    it "is true if above or equal to requirement" do
      Rails.application.config.cluster_credit_requirement = 10
      user.credits = 10
      expect(Ability.new(user).enough_credits_to_create_cluster?).to eq true
      user.credits = 11
      expect(Ability.new(user).enough_credits_to_create_cluster?).to eq true
    end
  end
end
