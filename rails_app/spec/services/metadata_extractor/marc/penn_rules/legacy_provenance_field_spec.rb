# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::LegacyProvenanceField do
  let(:field_mapping) { described_class.new(tag: '650', subfields: 'a') }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#apply?' do
    context 'when subfield $a is prefixed with PRO' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="4" tag="650" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">PRO Kaplan, Deanne (donor) (Kaplan Collection copy)</marc:subfield>
            <marc:subfield code="5">PU</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'return true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end

    context 'when subfield $a is not prefixed with PRO' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="7" tag="650" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Synagogue dedication services.</marc:subfield>
            <marc:subfield code="2">fast</marc:subfield>
            <marc:subfield code="0">http://id.worldcat.org/fast/1141014</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end
  end

  describe '#mapping' do
    context 'when subfield $a is prefixed with PRO' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="4" tag="650" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">PRO Kaplan, Deanne (donor) (Kaplan Collection copy)</marc:subfield>
            <marc:subfield code="5">PU</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns value with PRO removed' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'Kaplan, Deanne (donor) (Kaplan Collection copy)' }
        )
      end
    end

    context 'when subfield $a not prefixed with PRO' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="4" tag="650" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Kaplan, Deanne (donor) (Kaplan Collection copy)</marc:subfield>
            <marc:subfield code="5">PU</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns value' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'Kaplan, Deanne (donor) (Kaplan Collection copy)' }
        )
      end
    end
  end
end
