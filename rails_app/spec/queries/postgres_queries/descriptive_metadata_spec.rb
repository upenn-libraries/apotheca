# frozen_string_literal: true

RSpec.describe PostgresQueries::DescriptiveMetadata do
  subject(:query) { described_class.new query_service: query_service }

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  describe '#items_with_bibnumber' do
    include_context 'with successful Alma request' do
      let(:xml) { File.read(file_fixture('alma/marc_xml/book-1.xml')) }
    end

    context 'when there are items with bibnumbers' do
      let!(:item_ids) do
        [
          persist(:item_resource, :with_bibnumber),
          persist(:item_resource, :with_bibnumber)
        ].map(&:id)
      end

      it 'returns the expected items' do
        expect(query.items_with_bibnumber.map(&:id)).to match_array item_ids
      end
    end

    context 'when there are no items with bibnumbers' do
      before { 2.times { persist(:item_resource) } }

      it 'returns no items' do
        expect(query.items_with_bibnumber.size).to eq 0
      end
    end
  end
end
