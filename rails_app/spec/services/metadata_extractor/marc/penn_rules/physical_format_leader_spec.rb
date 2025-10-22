# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::PhysicalFormatLeader do
  let(:field_mapping) { described_class.new(tag: '655', subfields: 'a', uri: true) }
  let(:datafield) do
    doc = Nokogiri::XML::Document.parse(xml).remove_namespaces!
    leader = doc.at_xpath('//records/record/leader')
    MetadataExtractor::MARC::XMLDocument::Leader.new(leader, doc)
  end

  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <marc:records xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
        <marc:record>
          <marc:leader>07339cas a2201009 a 4500</marc:leader>
          <marc:controlfield tag="001">9931746853503681</marc:controlfield>
          <marc:controlfield tag="008">830729d18601926enkmr p       0   a0eng c</marc:controlfield>
        </marc:record>
      </marc:records>
    XML
  end

  describe '#transform' do
    it 'maps leader and control008 to expected value' do
      expect(field_mapping.transform(datafield)).to contain_exactly(
        { uri: 'http://vocab.getty.edu/aat/300026642', value: 'serials (publications)' },
        { uri: 'http://vocab.getty.edu/aat/300026657', value: 'periodicals' }
      )
    end
  end
end
