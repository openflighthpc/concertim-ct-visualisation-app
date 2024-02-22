require 'rails_helper'

RSpec.describe Ability, type: :model do
  let!(:user) { create(:user) }

  describe "#enough_credits_to_create_cluster?" do
    it "is false if zero" do
      user.credits = 0
      expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
    end

    context 'user has team' do

      shared_examples 'is admin for another team' do
        let!(:another_team_role) { create(:team_role, user: user, team: another_team, role: "admin") }

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

      context 'user is a member' do
        let!(:team_role) { create(:team_role, user: user, team: team, role: "member") }

        it 'is false' do
          expect(Ability.new(user).enough_credits_to_create_cluster?).to eq false
        end

        include_examples 'is admin for another team'
      end

      context 'user is admin' do
        let!(:team_role) { create(:team_role, user: user, team: team, role: "admin") }

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

        include_examples 'is admin for another team'
      end
    end
  end
end
