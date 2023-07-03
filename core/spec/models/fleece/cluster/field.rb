require 'rails_helper'

RSpec.describe Fleece::Cluster::Field, type: :model do
  let(:constraints) { [] }
  let(:type) { "string" }
  let(:details) do
    {
      "type" => type,
      "order" => 0,
      "default" => "mylovelycluster",
      "description" => "What your cluster is called.",
      "constraints" => constraints
    }
  end
  subject { build(:fleece_cluster_field, details: details) }

  it "sets attributes based on provided details" do
    expect(subject.type).to eq "string"
    expect(subject.order).to eq 0
    expect(subject.default).to eq "mylovelycluster"
    expect(subject.description).to eq "What your cluster is called."
  end

  it "sets default details" do
    expect(subject.hidden).to eq false
    expect(subject.immutable).to eq false
    expect(subject.constraints).to eq({})
    expect(subject.value).to eq "mylovelycluster"
  end

  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  it "is invalid without an id" do
    subject.id = nil
    expect(subject).to have_error(:id, :blank)
  end

  it "is invalid without a type" do
    subject.type = nil
    expect(subject).to have_error(:type, :blank)
  end

  it "is invalid with an unrecognised type" do
    subject.type = "pinball"
    expect(subject).to have_error(:type, :inclusion)
  end

  it "is invalid without an order" do
    subject.order = nil
    expect(subject).to have_error(:order, :blank)
  end

  describe 'string field' do
    context 'length constraint' do

      shared_examples 'minimum' do
        it 'must be above or equal to minimum length' do
          subject.value = "a"
          expect(subject).to have_error(:value, constraints[0]["description"])
          subject.value = "abc"
          expect(subject).to be_valid
        end
      end

      shared_examples 'maximum' do
        it 'must be below or equal to maximum length' do
          subject.value = "There are too many letters here"
          expect(subject).to have_error(:value, constraints[0]["description"])
          subject.value = "Less letters"
          expect(subject).to be_valid
        end
      end

      context 'includes both min and maximum' do
        let(:constraints) do
          [
            {
              "length"=>{"max"=>12, "min"=>3},
              "description"=>"must be between 3 and 12 characters"
            }
          ]
        end

        include_examples 'minimum'
        include_examples 'maximum'
      end

      context 'just minimum' do
        let(:constraints) do
          [
            {
              "length"=>{"min"=>3},
              "description"=>"must be at least 3 characters"
            }
          ]
        end

        include_examples 'minimum'
      end

      context 'just maximum' do
        let(:constraints) do
          [
            {
              "length"=>{"max"=>12},
              "description"=>"must be at most 12 characters"
            }
          ]
        end

        include_examples 'maximum'
      end
    end

    context 'pattern constraint' do
      let(:constraints) do
        [
          {
            "allowed_pattern" => "[A-Z]+[a-zA-Z0-9]*",
            "description" => "must start with an uppercase character"
          }
        ]
      end

      it 'must match pattern' do
        subject.value = "999123"
        expect(subject).to have_error(:value, "must start with an uppercase character")
        subject.value = "Ninety nine 9"
        expect(subject).to be_valid
      end
    end

    context 'allowed values constraint' do
      let(:constraints) do
        [
          {
            "allowed_values" => %w(fish chicken beef panda),
            "description" => "must be a type of meat"
          }
        ]
      end

      it 'must match an option' do
        subject.value = "tofu"
        expect(subject).to have_error(:value, "must be a type of meat")
        subject.value = "beef"
        expect(subject).to be_valid
      end
    end
  end

  describe 'number field' do
    let(:type) { "number" }

    # Values from forms are strings - we don't have active record magic auto-converting them
    it 'must be a valid number' do
      subject.value = "abc"
      expect(subject).to have_error(:value, "must be a valid number")
      subject.value = "1"
      expect(subject).to be_valid
      subject.value = "1.5"
      expect(subject).to be_valid
      subject.value = 7
      expect(subject).to be_valid
    end

    context 'modulo constraint' do
      context 'step and offset' do
        let(:constraints) do
          [
            {
              "modulo" => {"step" => 2.5, "offset" => 1},
              "description" => "must be a special number"
            }
          ]
        end

        it 'must match step and offset' do
          subject.value = "2.5"
          expect(subject).to have_error(:value, "must be a special number")
          subject.value = "6"
          expect(subject).to be_valid
        end
      end

      context 'only step' do
        let(:constraints) do
          [
            {
              "modulo" => {"step" => 13},
              "description" => "must be a special number"
            }
          ]
        end

        it 'must match step' do
          subject.value = "11"
          expect(subject).to have_error(:value, "must be a special number")
          subject.value = "26"
          expect(subject).to be_valid
        end
      end
    end

    context 'range constraint' do
      shared_examples 'minimum' do
        it 'must be above or equal to minimum' do
          subject.value = "1"
          expect(subject).to have_error(:value, constraints[0]["description"])
          subject.value = "5"
          expect(subject).to be_valid
        end
      end

      shared_examples 'maximum' do
        it 'must be below or equal to maximum' do
          subject.value = "999999"
          expect(subject).to have_error(:value, constraints[0]["description"])
          subject.value = "9"
          expect(subject).to be_valid
        end
      end

      context 'includes both min and maximum' do
        let(:constraints) do
          [
            {
              "range"=>{"max"=>12, "min"=>3},
              "description"=>"must be between 3 and 12"
            }
          ]
        end

        include_examples 'minimum'
        include_examples 'maximum'
      end

      context 'just minimum' do
        let(:constraints) do
          [
            {
              "range"=>{"min"=>3},
              "description"=>"must be at least 3"
            }
          ]
        end

        include_examples 'minimum'
      end

      context 'just maximum' do
        let(:constraints) do
          [
            {
              "range"=>{"max"=>12},
              "description"=>"must be at most 12"
            }
          ]
        end

        include_examples 'maximum'
      end
    end

    context 'allowed values constraint' do
      let(:constraints) do
        [
          {
            "allowed_values" => [1, 11, 111, 1111, 1.1111],
            "description" => "must be all ones"
          }
        ]
      end

      it 'must match an option' do
        subject.value = "22"
        expect(subject).to have_error(:value, "must be all ones")
        subject.value = "111"
        expect(subject).to be_valid
      end
    end
  end
end
