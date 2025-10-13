# frozen_string_literal: true

RSpec.describe SolrQueries::ItemIlsMetadata do
  subject(:query) { described_class.new query_service: query_service }

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  # stub RSolr get to return a controlled response
  before do
    rsolr = instance_double(RSolr::Client)
    allow(rsolr).to receive(:get).and_return(solr_response)
    allow(query_service).to receive(:connection).and_return(rsolr)
  end

  describe '#ils_metadata_for' do
    let(:hash) { query.ils_metadata_for id: 'test-id' }

    context 'with ILS metadata present' do
      let(:ils_metadata) { { 'identifier' => ['123456789'], 'date' => ['1976'] } }
      let(:solr_response) do
        { 'response' => { 'docs' => [
          { DescriptiveMetadataIndexer::ILS_METADATA_JSON_FIELD.to_s => ils_metadata.to_json }
        ] } }
      end

      it 'returns a Hash of ILS metadata' do
        expect(hash).to eq ils_metadata
      end
    end

    context 'without ILS metadata present' do
      let(:solr_response) do
        { 'response' => { 'docs' => [{}] } }
      end

      it 'returns nil' do
        expect(hash).to be_nil
      end
    end
  end
end
