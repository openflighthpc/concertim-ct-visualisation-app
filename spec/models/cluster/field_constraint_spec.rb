require 'rails_helper'

RSpec.describe Cluster::FieldConstraint, type: :model do
  subject {
    kwargs = {"description" => description}
    kwargs[type] = definition
    Cluster::FieldConstraint.new(**kwargs)
  }
  let(:description) { nil }

  before(:each) { subject.valid? }

  describe 'length constraint' do
    let(:type) { 'length' }

    context 'neither maximum nor minimum' do
      let(:definition) { {test: nil} }

      it 'fails validation of format' do
        expect(subject).to have_error(:length, 'must have a max and/or min')
      end
    end

    context 'maximum with a non number' do
      let(:definition) { {max: "abc"} }

      it 'fails validation of format' do
        expect(subject).to have_error(:length, 'max must be a valid number')
      end
    end

    context 'minimum with a non number' do
      let(:definition) { {min: "abc"} }

      it 'fails validation of format' do
        expect(subject).to have_error(:length, 'min must be a valid number')
      end
    end

    context 'both max and min are invalid' do
      let(:definition) { {min: "abc", max: nil} }

      it 'fails validation of format' do
        expect(subject).to have_error(:length, 'min must be a valid number')
        expect(subject).to have_error(:length, 'max must be a valid number')
      end
    end
  end

  describe "allowed_pattern constraint" do
    let(:type) { 'allowed_pattern' }
    context 'invalid pattern' do
      let(:definition) { "[" }

      it 'fails format validation' do
        expect(subject).to have_error(:allowed_pattern, "must be valid regex")
      end
    end
  end


  describe "allowed_values constraint" do
    let(:type) { 'allowed_values' }

    context 'allowed values are not a list' do
      let(:definition) { 123 }

      it 'fails format validation' do
        expect(subject).to have_error(:allowed_values, "must be an array of values")
      end
    end

    context 'empty allowed values list' do
      let(:definition) { [] }

      it 'fails format validation' do
        expect(subject).to have_error(:allowed_values, "must not be blank")
      end
    end
  end

  describe 'modulo constraint' do
    let(:type) { "modulo" }

    context 'invalid step' do
      let(:definition) { {"step" => "abc"} }

      it 'fails format validation' do
        expect(subject).to have_error(:modulo, "step must be a valid number")
      end
    end

    context 'invalid offset' do
      let(:definition) { {"step" => 2, "offset" => "abc"} }

      it 'fails format validation' do
        expect(subject).to have_error(:modulo, "offset must be empty or a valid number")
      end
    end

    context 'no step or offset' do
      let(:definition) { {test: nil} }

      it 'fails format validation' do
        expect(subject).to have_error(:modulo, "must contain step details")
      end
    end


  end
end
