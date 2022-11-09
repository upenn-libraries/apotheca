# frozen_string_literal: true

RSpec.describe DescriptiveMetadataIndexer do
  subject(:solr_hash) { described_class.new(resource: resource).to_solr }

  context 'when an item does not have a bibnumber' do
    let(:resource) { persist(:item_resource) }

    it { is_expected.to have_key :title_tesim }
    it { is_expected.to have_key :collection_tsim }
  end

  context 'when an item has a bibnumber' do
    let(:resource) { persist(:item_resource, descriptive_metadata: { bibnumber: '123' }) }
    # this is taken from spec/services/metadata_extractor/marmite/client_spec.rb
    # TODO: perhaps a shared context, or a stub/mock of the service injected into the indexer?
    let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }

    before do
      stub_request(:get, 'https://marmite.library.upenn.edu:9292/api/v2/records/123/marc21?update=always')
        .to_return(status: 200, body: marc_xml, headers: {})
    end

    it { is_expected.to have_key :title_tesim }
    it { is_expected.to have_key :collection_tsim }
  end

end
