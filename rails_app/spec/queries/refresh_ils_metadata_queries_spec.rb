# frozen_string_literal: true

RSpec.describe RefreshIlsMetadataQueries do
  subject(:query) { described_class.new query_service: query_service }

  # create two items without bibnumbers
  before do
    2.times { persist(:item_resource) }
  end

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  let(:items_with_bib) do
    # get the items by querying each object, not using the SQL query
    query_service.find_all_of_model(model: ItemResource).select do |item|
      item.descriptive_metadata.bibnumber.present?
    end
  end

  describe '#items_with_bibnumber' do
    include_context 'with successful Marmite request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    end

    context 'when there are items with bibnumbers' do
      # create two items with bibnumbers
      before do
        2.times { persist(:item_resource, :with_bibnumber) }
      end

      it 'returns the expected IDs' do
        expect(query.items_with_bibnumber).to match_array items_with_bib
      end
    end

    context 'when there are no items with bibnumbers' do
      it 'returns the expected IDs' do
        expect(query.items_with_bibnumber.size).to eq 0
      end
    end
  end
end
