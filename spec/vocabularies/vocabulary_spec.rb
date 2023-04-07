# frozen_string_literal: true

describe Vocabulary do
  subject(:vocabulary) { described_class }

  let(:dummy_class) { Class.new(described_class) }

  before do
    term = Data.define :label, :value
    dummy_class.const_set :TEST_TERM, term['cheesy', 'crunchy']
  end

  describe '.find_by' do
    it 'returns nil if constant is not defined' do
      expect(dummy_class.find_by(:label, 'none')).to be_nil
    end

    it "returns nil if field doesn't exist on term type" do
      expect(dummy_class.find_by(:quack, 'duck')).to be_nil
    end

    it 'returns the value of the constant if a match is found' do
      expect(dummy_class.find_by(:label, 'cheesy')).to be_a Data
    end
  end
end
