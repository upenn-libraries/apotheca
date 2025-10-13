# frozen_string_literal: true

describe PostgresQueries::ItemFinder do
  let(:query) do
    described_class.new(query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service)
  end

  describe '#find_by_unique_identifier' do
    let(:unique_identifier) { 'ark:/99999/fk4vx4' }
    let(:item) { persist(:item_resource, unique_identifier: unique_identifier) }

    before do
      item
      persist(:item_resource)
    end

    context 'when item with unique_identifier exists' do
      it 'returns expected item' do
        expect(query.find_by_unique_identifier(unique_identifier: unique_identifier).id).to eql item.id
      end
    end

    context 'when item with unique_identifier is not found' do
      it 'returns nil' do
        expect(query.find_by_unique_identifier(unique_identifier: 'ark:/random/random')).to be_nil
      end
    end
  end
end
