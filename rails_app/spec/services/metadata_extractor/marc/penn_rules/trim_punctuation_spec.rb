# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::TrimPunctuation do
  let(:cleanup) { described_class.new(fields: []) }

  describe '#apply' do
    context 'when values have trailing commas, colons or semicolons' do
      let(:values) do
        [{ value: 'Torelli, Achille,' }, { value: '[Paris] :' }, { value: '16 pages ; ' }]
      end
      let(:trimmed_values) do
        [{ value: 'Torelli, Achille' }, { value: '[Paris]' }, { value: '16 pages' }]
      end

      it 'removes trailing punctuation' do
        expect(cleanup.apply(values)).to match_array(trimmed_values)
      end
    end

    context 'when values have trailing period' do
      let(:values) do
        [{ value: 'Revolution, 1791-1804.' }, { value: 'Haiti. ' }, { value: 'A.B.' }]
      end
      let(:trimmed_values) do
        [{ value: 'Revolution, 1791-1804' }, { value: 'Haiti' }, { value: 'A.B.' }]
      end

      it 'removes trailing punctuation' do
        expect(cleanup.apply(values)).to match_array(trimmed_values)
      end
    end

    context 'when values have roles' do
      let(:values) do
        [{ value: 'Potier de Lille, Louis, 1750?-1794,', role: [{ value: 'printer.' }] }]
      end
      let(:trimmed_values) do
        [{ value: 'Potier de Lille, Louis, 1750?-1794', role: [{ value: 'printer' }] }]
      end

      it 'removes trailing punctuation from roles' do
        expect(cleanup.apply(values)).to match_array(trimmed_values)
      end
    end
  end
end
