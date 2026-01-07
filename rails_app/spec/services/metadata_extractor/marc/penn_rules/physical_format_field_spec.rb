# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::PhysicalFormatField do
  let(:field_mapping) { described_class.new(tag: '655', subfields: 'a', uri: true) }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#perform' do
    context 'when field is lcgft term' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="7" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Scores.</marc:subfield>
            <marc:subfield code="2">lcgft</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/genreForms/gf2014027077</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'maps value to AAT' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: 'scores (documents for music)', uri: 'http://vocab.getty.edu/aat/300026427' }
        )
      end
    end

    context 'when field is lcsh term' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Manuscripts.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/subjects/gf2022026088</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'maps value to AAT' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: 'manuscripts (documents)', uri: 'http://vocab.getty.edu/aat/300028569' }
        )
      end
    end

    context 'when field is lcsh term without URI' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Hybrid Music</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns value' do
        expect(field_mapping.perform(datafield)).to contain_exactly({ value: 'Hybrid Music' })
      end
    end

    context 'when field is rbmscv' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="7" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Menus</marc:subfield>
            <marc:subfield code="2">rbmscv</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/vocabulary/rbmscv/cv01585</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'maps value to AAT' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: 'menus', uri: 'http://vocab.getty.edu/aat/300027191' }
        )
      end
    end

    context 'when field is aat term' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="7" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">treatises</marc:subfield>
            <marc:subfield code="2">aat</marc:subfield>
            <marc:subfield code="0">http://vocab.getty.edu/aat/300026681</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns value' do
        expect(field_mapping.perform(datafield)).to contain_exactly(
          { value: 'treatises', uri: 'http://vocab.getty.edu/aat/300026681' }
        )
      end
    end
  end

  describe '#perform?' do
    context 'when field is one of the preferred authorities' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Manuscripts.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/subjects/gf2022026088</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end

    context 'when field is not one of the preferred authorities' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="7" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Piano music.</marc:subfield>
            <marc:subfield code="2">fast</marc:subfield>
            <marc:subfield code="0">http://id.worldcat.org/fast/1063403</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.perform?(datafield)).to be false
      end
    end

    context 'when field has an indicator2 equal to zero' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Hybrid Music</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end
  end
end
