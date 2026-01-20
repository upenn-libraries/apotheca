# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::AdditionalNameField do
  let(:field_mapping) { described_class.new(tag: '700', subfields: %w[a b c d g j q]) }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#mapping' do
    context 'when datafield has no roles' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Hodgson, James,</marc:subfield>
            <marc:subfield code="d">1672-1755.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n86845574</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns name' do
        expect(field_mapping.mapping(datafield)).to contain_exactly({ value: 'Hodgson, James, 1672-1755.' })
      end
    end

    context 'when datafield only has name roles' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Booth, Junius Brutus,</marc:subfield>
            <marc:subfield code="d">1796-1852,</marc:subfield>
            <marc:subfield code="e">actor.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n82201391</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns name value with roles' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'Booth, Junius Brutus, 1796-1852,', role: [{ value: 'actor.' }] }
        )
      end
    end

    context 'when datafield has a name and a provenance role' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Berendt, C. Hermann</marc:subfield>
            <marc:subfield code="q">(Carl Hermann),</marc:subfield>
            <marc:subfield code="d">1817-1878,</marc:subfield>
            <marc:subfield code="e">scribe,</marc:subfield>
            <marc:subfield code="e">former owner.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n93073368</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns name with only name roles' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'Berendt, C. Hermann (Carl Hermann), 1817-1878,', role: [{ value: 'scribe,' }] }
        )
      end
    end
  end

  describe '#apply?' do
    context 'when datafield is not related work, provenance name or collection name' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Hodgson, James,</marc:subfield>
            <marc:subfield code="d">1672-1755.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n86845574</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end

    context 'when datafield is related work' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2="2" tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Girard, François Narcisse,</marc:subfield>
            <marc:subfield code="d">1796-1825.</marc:subfield>
            <marc:subfield code="t">Traité de l'age du cheval.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end

    context 'when datafield is a provenance name' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Berendt, C. Hermann</marc:subfield>
            <marc:subfield code="q">(Carl Hermann),</marc:subfield>
            <marc:subfield code="d">1817-1878,</marc:subfield>
            <marc:subfield code="e">former owner.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n93073368</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end

    context 'when datafield is a collection name' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="2" ind2=" " tag="710" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)</marc:subfield>
            <marc:subfield code="5">PU</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end

    context 'when datafield has a name and a provenance role' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="700" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Berendt, C. Hermann</marc:subfield>
            <marc:subfield code="q">(Carl Hermann),</marc:subfield>
            <marc:subfield code="d">1817-1878,</marc:subfield>
            <marc:subfield code="e">scribe,</marc:subfield>
            <marc:subfield code="e">former owner.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/names/n93073368</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end
  end
end
