# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::ItemTypeField do
  let(:field_mapping) { described_class.new(tag: '336', subfields: 'a') }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#perform' do
    let(:xml) do
      <<~XML
        <marc:datafield ind1=" " ind2=" " tag="336" xmlns:marc="http://www.loc.gov/MARC21/slim">
          <marc:subfield code="a">text</marc:subfield>
          <marc:subfield code="b">txt</marc:subfield>
          <marc:subfield code="2">rdacontent</marc:subfield>
        </marc:datafield>
      XML
    end

    it 'maps type to expected DCMI term' do
      expect(field_mapping.perform(datafield)).to contain_exactly(
        { value: 'Text', uri: 'http://purl.org/dc/dcmitype/Text' }
      )
    end
  end

  describe '#perform?' do
    context 'when source is rdacontent' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2=" " tag="336" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">text</marc:subfield>
            <marc:subfield code="b">txt</marc:subfield>
            <marc:subfield code="2">rdacontent</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end

    context 'when source is not rdacontent' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2=" " tag="336" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">text</marc:subfield>
            <marc:subfield code="b">txt</marc:subfield>
            <marc:subfield code="2">rbmscv</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.perform?(datafield)).to be false
      end
    end
  end
end
