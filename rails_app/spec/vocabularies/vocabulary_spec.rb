# frozen_string_literal: true

describe Vocabulary do
  subject(:vocabulary) { described_class }

  let(:dummy_class) do
    Class.new(described_class) do |klass|
      term = Data.define :label, :value
      klass.const_set :TEST_TERM, term['cheesy', 'crunchy']
    end
  end

  describe '.find_by' do
    it 'returns nil if constant is not defined' do
      expect(dummy_class.find_by(label: 'none')).to be_nil
    end

    it "returns nil if field doesn't exist on term type" do
      expect(dummy_class.find_by(label: 'duck')).to be_nil
    end

    it 'returns the value of the constant if a match is found using a single condition' do
      expect(dummy_class.find_by(label: 'cheesy')).to be_a Data
    end

    it 'returns the value of the constant if a match is found with multiple conditions' do
      expect(dummy_class.find_by(label: 'cheesy', value: 'crunchy')).to be_a Data
    end
  end
end
