# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::DateField do
  let(:field_mapping) { described_class.new(tag: '008') }
  let(:document) do
    MetadataExtractor::MARC::XMLDocument.new(
      <<~XML
        <record>
          <controlfield tag="008">#{controlfield_value}</controlfield>
        </record>
      XML
    )
  end
  let(:controlfield) { document.controlfields.find { |field| field.tag == '008' } }

  describe '#apply?' do
    context 'when controlfield indicates no date given or a BC date' do
      let(:controlfield_value) { '110617b ua 000 0 egy d ' }

      it 'returns false' do
        expect(field_mapping.apply?(controlfield)).to be false
      end
    end
  end

  describe '#mapping' do
    context 'when controlfield contains a singular date' do
      let(:controlfield_value) { '850605s1753 enkabcf 000 0 eng d' }

      it 'extracts year' do
        expect(field_mapping.mapping(controlfield)).to eql([{ value: '1753' }])
      end
    end

    context 'when controlfield contains a date range with both dates' do
      let(:controlfield_value) { '030101i10uu11uuxx 000 0 heb d' }

      it 'converts date to EDFT' do
        expect(field_mapping.mapping(controlfield)).to eql([{ value: '10XX/11XX' }])
      end
    end

    context 'when controlfield contains a date range with only end date' do
      let(:controlfield_value) { '030101iuuuu11uuxx 000 0 heb d' }

      it 'converts date to EDFT' do
        expect(field_mapping.mapping(controlfield)).to eql([{ value: '/11XX' }])
      end
    end

    context 'when controlfield contains a date range with only start date' do
      let(:controlfield_value) { '030101i10uuuuuuxx 000 0 heb d' }

      it 'converts date to EDFT' do
        expect(field_mapping.mapping(controlfield)).to eql [{ value: '10XX/' }]
      end
    end

    context 'when controlfield contains a date range with an open date range' do
      let(:controlfield_value) { '891003m19139999tu ac 000 0dota d' }

      it 'converts date to EDFT' do
        expect(field_mapping.mapping(controlfield)).to eql [{ value: '1913/..' }]
      end
    end

    context 'when controlfield contains a blank date value' do
      let(:controlfield_value) { '121105b        pau           000 0 akk d' }

      it 'sets blank date' do
        expect(field_mapping.mapping(controlfield)).to eql []
      end
    end

    context 'when controlfield contains approximate date value' do
      let(:controlfield_value) { '030101q10uu11uuxx 000 0 heb d' }

      it 'converts date to EDFT' do
        expect(field_mapping.mapping(controlfield)).to contain_exactly({ value: '10XX' })
      end
    end
  end
end
