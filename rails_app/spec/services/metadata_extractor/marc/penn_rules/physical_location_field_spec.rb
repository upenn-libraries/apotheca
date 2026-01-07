# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::PhysicalLocationField do
  let(:field_mapping) { described_class.new(tag: 'AVA') }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    MetadataExtractor::MARC::XMLDocument::DataField.new(doc.children.first, doc)
  end

  describe '#perform' do
    let(:xml) do
      <<~XML
        <marc:datafield ind1=" " ind2=" " tag="AVA" xmlns:marc="http://www.loc.gov/MARC21/slim">
          <marc:subfield code="0">9951469283503681</marc:subfield>
          <marc:subfield code="8">22324855100003681</marc:subfield>
          <marc:subfield code="a">01UPENN_INST</marc:subfield>
          <marc:subfield code="b">KislakCntr</marc:subfield>
          <marc:subfield code="c">Rare Book Collection</marc:subfield>
          <marc:subfield code="d">FC75 F8448 box 28 no. 771</marc:subfield>
          <marc:subfield code="e">check_holdings</marc:subfield>
          <marc:subfield code="j">scrare</marc:subfield>
          <marc:subfield code="k">8</marc:subfield>
          <marc:subfield code="p">1</marc:subfield>
          <marc:subfield code="q">Kislak Center for Special Collections</marc:subfield>
        </marc:datafield>
      XML
    end

    it 'returns expected value' do
      expect(field_mapping.perform(datafield)).to contain_exactly(
        { value: 'Kislak Center for Special Collections, Rare Book Collection, FC75 F8448 box 28 no. 771' }
      )
    end
  end

  describe '#perform?' do
    context 'when subfield 8 present' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2=" " tag="AVA" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="0">9951469283503681</marc:subfield>
            <marc:subfield code="8">22324855100003681</marc:subfield>
            <marc:subfield code="q">Kislak Center for Special Collections, Rare Books and Manuscripts</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns true' do
        expect(field_mapping.perform?(datafield)).to be true
      end
    end

    context 'when subfield 8 is not present' do
      let(:xml) do
        <<~XML
          <marc:datafield ind1=" " ind2=" " tag="AVA" xmlns:marc="http://www.loc.gov/MARC21/slim">
            <marc:subfield code="0">9951469283503681</marc:subfield>
            <marc:subfield code="q">Kislak Center for Special Collections, Rare Books and Manuscripts</marc:subfield>
          </marc:datafield>
        XML
      end

      it 'returns false' do
        expect(field_mapping.perform?(datafield)).to be false
      end
    end
  end
end
