# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::BCEDateField do
  let(:field_mapping) { described_class.new(tag: '046') }
  let(:controlfield) { '110617b ua 000 0 egy d' }
  let(:document) do
    MetadataExtractor::MARC::XMLDocument.new(
      <<~XML
        <record>
          <controlfield tag="008">#{controlfield}</controlfield>
          #{datafield_tag}
        </record>
      XML
    )
  end
  let(:datafield) { document.datafields.find { |field| field.tag == '046' } }

  describe '#apply?' do
    context 'when controlfield indicates no date given or a BC date' do
      let(:datafield_tag) do
        <<~XML
          <datafield ind1=" " ind2=" " tag="046">
            <subfield code="a">q</subfield>
          </datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end

    context 'when controlfield indicates a non-BC date' do
      let(:controlfield) { '850605s1753 enkabcf 000 0 eng d' }
      let(:datafield_tag) do
        <<~XML
          <datafield ind1=" " ind2=" " tag="046">
            <subfield code="a">q</subfield>
          </datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end
  end

  describe '#mapping' do
    context 'when datafield contains a singular date' do
      let(:datafield_tag) do
        <<~XML
          <datafield ind1=" " ind2=" " tag="046">
            <subfield code="a">s</subfield>
            <subfield code="b">200</subfield>
          </datafield>
        XML
      end

      it 'returns a properly formatted EDTF date' do
        expect(field_mapping.mapping(datafield)).to eql [{ value: '-0200' }]
      end
    end

    context 'when datafield contains a date range' do
      let(:datafield_tag) do
        <<~XML
          <datafield ind1=" " ind2=" " tag="046">
            <subfield code="a">i</subfield>
            <subfield code="b">205</subfield>
            <subfield code="d">200</subfield>
          </datafield>
        XML
      end

      it 'returns a properly formatted EDTF date range' do
        expect(field_mapping.mapping(datafield)).to eql [{ value: '-0205/-0200' }]
      end
    end
  end
end
