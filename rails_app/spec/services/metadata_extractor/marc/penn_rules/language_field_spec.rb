# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::LanguageField do
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end
  let(:controlfield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::ControlField.new(doc.children.first, doc)
  end

  describe '#perform' do
    context 'when transforming controlfield' do
      let(:field_mapping) { described_class.new(tag: '008', chars: (35..37).to_a) }
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">870304s1931    nyu           000 1 eng  </marc:controlfield>
        XML
      end
      let(:expected_languages) do
        [{ value: 'English', uri: 'http://id.loc.gov/vocabulary/iso639-2/eng' }]
      end

      it 'extracts expected languages' do
        expect(field_mapping.perform(controlfield)).to match_array(expected_languages)
      end
    end

    context 'when transforming datafield' do
      let(:field_mapping) { described_class.new(tag: '041', subfields: %w[a b g]) }
      let(:xml) do
        <<~XML
          <marc:datafield ind1="1" ind2=" " tag="041" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">eng</marc:subfield>
            <marc:subfield code="a">spa</marc:subfield>
            <marc:subfield code="a">sai</marc:subfield>
            <marc:subfield code="a">cai</marc:subfield>
            <marc:subfield code="b">chb</marc:subfield>
            <marc:subfield code="b">ger</marc:subfield>
          </marc:datafield>
        XML
      end
      let(:expected_languages) do
        [
          { value: 'English', uri: 'http://id.loc.gov/vocabulary/iso639-2/eng' },
          { value: 'Spanish; Castilian', uri: 'http://id.loc.gov/vocabulary/iso639-2/spa' },
          { value: 'South American Indian languages', uri: 'http://id.loc.gov/vocabulary/iso639-2/sai' },
          { value: 'Central American Indian languages', uri: 'http://id.loc.gov/vocabulary/iso639-2/cai' },
          { value: 'Chibcha', uri: 'http://id.loc.gov/vocabulary/iso639-2/chb' },
          { value: 'German', uri: 'http://id.loc.gov/vocabulary/iso639-2/ger' }
        ]
      end

      it 'extracts expected languages' do
        expect(field_mapping.perform(datafield)).to match_array(expected_languages)
      end
    end
  end

  describe '#perform?' do
    context 'when given a controlfield with matching tag' do
      let(:field_mapping) { described_class.new(tag: '008', chars: (35..37).to_a) }
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">870304s1931    nyu           000 1 eng  </marc:controlfield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(controlfield)).to be true
      end
    end

    context 'when given a datafield with matching tag' do
      let(:field_mapping) { described_class.new(tag: '041', subfields: 'a') }
      let(:xml) do
        <<~XML
           <marc:datafield ind1="1" ind2=" " tag="041" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">eng</marc:subfield>
            <marc:subfield code="b">rus</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end

    context 'when it does not match tag' do
      let(:field_mapping) { described_class.new(tag: '042', subfields: 'a') }
      let(:xml) do
        <<~XML
           <marc:datafield ind1="1" ind2=" " tag="041" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="a">eng</marc:subfield>
            <marc:subfield code="b">rus</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.perform?(datafield)).to be false
      end
    end
  end
end
