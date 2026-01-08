# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::DataField do
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#mapping' do
    context 'when selecting a subset of subfields' do
      let(:field_mapping) { described_class.new(tag: '650', subfields: %w[a v z]) }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="650" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">First Coalition, War of the, 1792-1797</marc:subfield>
            <marc:subfield code="x">Campaigns</marc:subfield>
            <marc:subfield code="z">Italy</marc:subfield>
            <marc:subfield code="v">Early works to 1800.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns expected value' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'First Coalition, War of the, 1792-1797 Italy Early works to 1800.' }
        )
      end
    end

    context 'when selecting repeatable subfields' do
      let(:field_mapping) { described_class.new(tag: '651', subfields: 'a'..'z') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="651" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">France</marc:subfield>
            <marc:subfield code="x">History</marc:subfield>
            <marc:subfield code="y">Reign of Terror, 1793-1794</marc:subfield>
            <marc:subfield code="x">Food supply.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns expected value' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'France History Reign of Terror, 1793-1794 Food supply.' }
        )
      end
    end

    context 'when selecting all subfields' do
      let(:field_mapping) { described_class.new(tag: '651') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="651" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">France</marc:subfield>
            <marc:subfield code="x">History</marc:subfield>
            <marc:subfield code="y">Reign of Terror, 1793-1794</marc:subfield>
            <marc:subfield code="x">Food supply.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns expected values' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'France History Reign of Terror, 1793-1794 Food supply.' }
        )
      end
    end

    context 'when joining subfields' do
      let(:field_mapping) { described_class.new(tag: '651', subfields: 'a'..'z', join: ' -- ') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="651" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">France</marc:subfield>
            <marc:subfield code="x">History</marc:subfield>
            <marc:subfield code="y">Reign of Terror, 1793-1794</marc:subfield>
            <marc:subfield code="x">Food supply.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'correctly joins subfields' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'France -- History -- Reign of Terror, 1793-1794 -- Food supply.' }
        )
      end
    end

    context 'when adding prefix to values' do
      let(:field_mapping) { described_class.new(tag: '505', subfields: 'a'..'z', prefix: 'Table of contents: ') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1="0" ind2="0" tag="505" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">formatted contents note</marc:subfield>
            <marc:subfield code="r">statement of responsibility</marc:subfield>
            <marc:subfield code="t">title</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'prepends prefix' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'Table of contents: formatted contents note statement of responsibility title' }
        )
      end
    end

    context 'when extracting uri' do
      let(:field_mapping) { described_class.new(tag: '650', subfields: 'a'..'z', uri: true) }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="650" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Indians of South America</marc:subfield>
            <marc:subfield code="z">Colombia</marc:subfield>
            <marc:subfield code="x">Languages.</marc:subfield>
            <marc:subfield code="0">http://id.loc.gov/authorities/subjects/sh85065601</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'includes uri' do
        expect(field_mapping.mapping(datafield)).to contain_exactly(
          { value: 'Indians of South America Colombia Languages.',
            uri: 'http://id.loc.gov/authorities/subjects/sh85065601' }
        )
      end
    end
  end

  describe '#apply?' do
    context 'when type and tag match' do
      let(:field_mapping) { described_class.new(tag: '500') }

      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2=" " tag="500" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Ms. codex.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end

    context 'when type, tag and indicator2 match' do
      let(:field_mapping) { described_class.new(tag: '655', indicator2: '0') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Manuscripts, American.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.apply?(datafield)).to be true
      end
    end

    context 'when tag does not match' do
      let(:field_mapping) { described_class.new(tag: '500') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Manuscripts, American.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end

    context 'when indicator2 does not match' do
      let(:field_mapping) { described_class.new(tag: '655', indicator2: '1') }
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2="0" tag="655" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">Manuscripts, American.</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.apply?(datafield)).to be false
      end
    end
  end
end
