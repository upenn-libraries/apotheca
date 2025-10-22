# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::DateField do
  let(:field_mapping) { described_class.new(tag: '008') }
  let(:controlfield) do
    doc = Nokogiri::XML::DocumentFragment.parse(xml).children.first
    MetadataExtractor::MARC::XMLDocument::ControlField.new(doc.children.first, doc)
  end

  describe '#transform' do
    context 'when controlfield contains a singular date' do
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">850605s1753 enkabcf 000 0 eng d</marc:controlfield>
        XML
      end

      it 'extracts year' do
        expect(field_mapping.transform(controlfield)).to eql([{ value: '1753' }])
      end
    end

    context 'when controlfield contains a date range with both dates' do
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">030101i10uu11uuxx 000 0 heb d</marc:controlfield>
        XML
      end

      it 'converts date to EDFT' do
        expect(field_mapping.transform(controlfield)).to eql([{ value: '10XX/11XX' }])
      end
    end

    context 'when controlfield contains a date range with only end date' do
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">030101iuuuu11uuxx 000 0 heb d</marc:controlfield>
        XML
      end

      it 'converts date to EDFT' do
        expect(field_mapping.transform(controlfield)).to eql([{ value: '/11XX' }])
      end
    end

    context 'when controlfield contains a date range with only start date' do
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">030101i10uuuuuuxx 000 0 heb d</marc:controlfield>
        XML
      end

      it 'converts date to EDFT' do
        expect(field_mapping.transform(controlfield)).to eql [{ value: '10XX/' }]
      end
    end

    context 'when controlfield contains a blank date value' do
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">121105b        pau           000 0 akk d</marc:controlfield>
        XML
      end

      it 'sets blank date' do
        expect(field_mapping.transform(controlfield)).to eql []
      end
    end

    context 'when controlfield contains approximate date value' do
      let(:xml) do
        <<~XML
          <marc:controlfield tag="008">030101q10uu11uuxx 000 0 heb d</marc:controlfield>
        XML
      end

      it 'converts date to EDFT' do
        expect(field_mapping.transform(controlfield)).to contain_exactly({ value: '10XX' })
      end
    end
  end
end
