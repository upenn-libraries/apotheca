# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::CollectionNameField do
  let(:field_mapping) { described_class.new(tag: '710', subfields: 'a') }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#apply?' do
    context 'when datafield is a collection field' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="2" ind2=" " tag="710" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)</marc:subfield>
            <marc:subfield code="5">PU</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end

    context 'when datafield is not a collection field' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="2" ind2=" " tag="710" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)</marc:subfield>
            <marc:subfield code="5">INCORRECT</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end
  end
end
