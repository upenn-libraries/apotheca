# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::TransliteratedTitleField do
  let(:field_mapping) { described_class.new(tag: '880', subfields: 'a'..'z') }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#perform?' do
    context 'when datafield contains transliterated title' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="0" ind2="0" tag="880" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="6">245-01//r</marc:subfield>
            <marc:subfield code="a">慶安太平記</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end

    context 'when datafield does not contain transliterated title' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="0" ind2="0" tag="880" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="6">246-01//r</marc:subfield>
            <marc:subfield code="a">慶安太平記</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.perform?(datafield)).to be false
      end
    end
  end
end
