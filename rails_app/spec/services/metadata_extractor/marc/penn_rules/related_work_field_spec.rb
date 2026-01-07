# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::RelatedWorkField do
  let(:field_mapping) { described_class.new(tag: '700', subfields: ('a'..'z').to_a, join: ' ') }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#perform' do
    context 'when 7XX datafield contains a related work' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2="2" tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Girard, François Narcisse,</marc:subfield>
            <marc:subfield code="d">1796-1825.</marc:subfield>
            <marc:subfield code="t">Traité de l'age du cheval.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'extracts related work' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: "Related Work: Girard, François Narcisse, 1796-1825. Traité de l'age du cheval." }
        )
      end
    end
  end

  describe '#perform?' do
    context 'when datafield is a related work' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2="2" tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Girard, François Narcisse,</marc:subfield>
            <marc:subfield code="d">1796-1825.</marc:subfield>
            <marc:subfield code="t">Traité de l'age du cheval.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end

    context 'when datafield is not a related work' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700"xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Torelli, Achille,</marc:subfield>
            <marc:subfield code="d">1844-1922.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/no00004666</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.perform?(datafield)).to be false
      end
    end
  end
end
