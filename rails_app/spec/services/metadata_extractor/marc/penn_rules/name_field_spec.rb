# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::NameField do
  let(:field_mapping) { described_class.new(tag: '100', subfields: %w[a b c d g j q]) }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#perform' do
    context 'when name field has roles' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="100" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Mendes, Frederick de Sola,</marc:subfield>
            <marc:subfield code="d">1850-1927,</marc:subfield>
            <marc:subfield code="e">author,</marc:subfield>
            <marc:subfield code="e">publisher.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n98021637</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns name value with roles' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: 'Mendes, Frederick de Sola, 1850-1927,', role: [{ value: 'author,' }, { value: 'publisher.' }] }
        )
      end
    end

    context 'when name field has no roles' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="0" ind2=" " tag="100" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Pius</marc:subfield>
            <marc:subfield code="b">III,</marc:subfield>
            <marc:subfield code="c">Pope,</marc:subfield>
            <marc:subfield code="d">approximately 1440-1503.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/nr97025599</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns value' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: 'Pius III, Pope, approximately 1440-1503.' }
        )
      end
    end
  end
end
