# frozen_string_literal: true

describe ChangeSet do
  let(:change_set) { described_class.new(Valkyrie::Resource.new) }

  describe '#compact_value' do
    it 'removes empty values from array' do
      expect(change_set.compact_value([nil, '', 'value'])).to eql ['value']
    end

    it 'removes empty values from nested hashes' do
      expect(
        change_set.compact_value({ value: 'Random, Person', uri: '', role: [{ value: '' }] })
      ).to eql ({ value: 'Random, Person' })
    end

    it 'removes empty values from an array with hashes' do
      expect(
        change_set.compact_value([{ value: '' }, { value: 'Cats', uri: '' }])
      ).to eql ([{ value: 'Cats' }])
    end

    it 'converts empty strings to nil' do
      expect(change_set.compact_value('')).to eql nil
    end
  end
end