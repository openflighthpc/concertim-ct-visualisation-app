require 'rails_helper'

RSpec.describe Ability, type: :model do
  let!(:user) { create(:user) }
  let!(:team) { create(:team) }
  let!(:another_team) { create(:team) }

  describe "#enough_credits_to_create_cluster?" do
    context 'user has no team' do
      it "is false if user has no team" do
        expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
      end
    end

    context 'user has team' do
      let!(:team_role) { create(:team_role, user: user, team: team) }

      it "is false if team has no credits" do
        team.credits = 0
        team.save!
        expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
      end

      it "is false if below set requirement" do
        Rails.application.config.cluster_credit_requirement = 10
        team.credits = 9
        team.save!
        expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
      end

      it "is true if above or equal to requirement" do
        Rails.application.config.cluster_credit_requirement = 10
        team.credits = 10
        team.save!
        expect(Ability.new(user).enough_credits_to_create_cluster?).to eq true
        team.credits = 11
        team.save!
        expect(Ability.new(user).enough_credits_to_create_cluster?).to eq true
      end

      context 'has another team' do
        let!(:another_team_role) { create(:team_role, user: user, team: another_team) }

        it 'it is true if at least one team above or equal to requirement' do
          team.credits = 0
          team.save!
          Rails.application.config.cluster_credit_requirement = 10
          another_team.credits = 10
          another_team.save!
          expect(Ability.new(user).enough_credits_to_create_cluster?).to eq true
          another_team.credits = 11
          another_team.save!
          expect(Ability.new(user).enough_credits_to_create_cluster?).to eq true
        end
      end
    end
  end
end
