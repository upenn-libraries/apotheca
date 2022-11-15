# frozen_string_literal: true

RSpec.describe ItemIndex do
  subject(:query) { described_class.new query_service: query_service }

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  before do
    persist(:item_resource, descriptive_metadata: { title: 'Cheesy Item', collection: 'Collection B' })
    persist(:item_resource, descriptive_metadata: { title: 'Crunchy Item', collection: 'Collection A' })
  end

  describe '#item_index' do
    let(:parameters) { ActionController::Parameters.new(params_hash) }
    let(:items) { query_service.custom_queries.item_index(parameters: parameters).documents }

    context 'with a keyword search' do
      let(:params_hash) { { keyword: 'Crunchy' } }

      it 'returns result from title field' do
        expect(items.count).to eq 1
        expect(items.first.descriptive_metadata.title).to match_array 'Crunchy Item'
      end
    end

    context 'with an ascending title sort' do
      let(:params_hash) { { sort_field: 'title_tsi', sort_direction: 'asc' } }

      it 'returns result properly ordered' do
        expect(items.count).to eq 2
        expect(items.first.descriptive_metadata.title).to match_array 'Cheesy Item'
      end
    end

    context 'with descending title sort' do
      let(:params_hash) { { sort_field: 'title_tsi', sort_direction: 'desc' } }

      it 'returns result properly ordered' do
        expect(items.count).to eq 2
        expect(items.first.descriptive_metadata.title).to match_array 'Crunchy Item'
      end
    end

    context 'with collection filter applied' do
      let(:params_hash) { { filters: { collection_ssim: 'Collection A' } } }

      it 'returns only Collection A item' do
        expect(items.count).to eq 1
        expect(items.first.descriptive_metadata.collection).to match_array 'Collection A'
      end
    end
  end
end
