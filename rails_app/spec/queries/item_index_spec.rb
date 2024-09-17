# frozen_string_literal: true

RSpec.describe ItemIndex do
  subject(:query) { described_class.new query_service: query_service }

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  before do
    persist(:item_resource,
            descriptive_metadata: { title: [{ value: 'Cheesy Item' }], collection: [{ value: 'Collection B' }] })
    persist(:item_resource,
            descriptive_metadata: { title: [{ value: 'Crunchy Item' }], collection: [{ value: 'Collection A' }] })
  end

  shared_examples_for 'a solr query' do
    context 'with a keyword search' do
      let(:params_hash) { { search: { all: 'Crunchy' } } }

      it 'returns result from title field' do
        expect(items.count).to eq 1
        expect(items.first.descriptive_metadata.title.pluck(:value)).to match_array 'Crunchy Item'
      end
    end

    context 'with an ascending title sort' do
      let(:params_hash) { { sort: { field: 'title', direction: 'asc' } } }

      it 'returns result properly ordered' do
        expect(items.count).to eq 2
        expect(items.first.descriptive_metadata.title.pluck(:value)).to match_array 'Cheesy Item'
      end
    end

    context 'with descending title sort' do
      let(:params_hash) { { sort: { field: 'title', direction: 'desc' } } }

      it 'returns result properly ordered' do
        expect(items.count).to eq 2
        expect(items.first.descriptive_metadata.title.pluck(:value)).to match_array 'Crunchy Item'
      end
    end

    context 'with collection filter applied' do
      let(:params_hash) { { filter: { collection: 'Collection A' } } }

      it 'returns only Collection A item' do
        expect(items.count).to eq 1
        expect(items.first.descriptive_metadata.collection.pluck(:value)).to match_array 'Collection A'
      end
    end

    context 'with multiple collection filters applied' do
      let(:collections) { ['Collection A', 'Collection B'] }
      let(:params_hash) { { filter: { collection: collections } } }

      it 'returns Collection A and Collection B items' do
        expect(items.count).to eq 2
        returned_collections = items.collect { |i| i.descriptive_metadata.collection.pluck(:value) }.flatten
        expect(returned_collections).to match_array collections
      end
    end
  end

  describe '#item_index' do
    let(:parameters) { ActionController::Parameters.new(params_hash).permit! }
    let(:items) { query_service.custom_queries.item_index(parameters: parameters).documents }

    it_behaves_like 'a solr query'
  end

  describe '#item_index_all' do
    let(:parameters) { ActionController::Parameters.new(params_hash).permit! }
    let(:items) { query_service.custom_queries.item_index_all(parameters: parameters).documents }

    it_behaves_like 'a solr query'

    context 'with page and row parameters' do
      let(:params_hash) { { page: 1, rows: 1 } }

      it 'returns all results' do
        expect(items.count).to eq 2
      end
    end
  end
end
