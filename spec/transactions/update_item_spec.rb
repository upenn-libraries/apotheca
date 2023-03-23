# frozen_string_literal: true

describe UpdateItem do
  describe '#call' do
    include_context 'with successful requests to update EZID'

    let(:transaction) { described_class.new }
    let(:item) { persist(:item_resource) }

    context 'when all required attributes present' do
      subject(:updated_item) { result.value! }

      let(:result) do
        transaction.call(
          id: item.id,
          human_readable_name: 'Updated Item',
          descriptive_metadata: { subject: ['Cataloging', 'Animals'] },
          asset_ids: [asset.id],
          updated_by: 'admin@example.com'
        )
      end
      let(:asset) { persist(:asset_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'updated human_readable_name' do
        expect(updated_item.human_readable_name).to eql 'Updated Item'
      end

      it 'merges descriptive metadata' do
        expect(
          updated_item.descriptive_metadata
        ).to include(title: ['New Item'], subject: ['Cataloging', 'Animals'])
      end

      it 'sets thumbnail asset id' do
        expect(updated_item.thumbnail_asset_id).to eql asset.id
      end
    end

    context 'when updated_by is not provided' do
      subject(:result) do
        transaction.call(
          id: item.id,
          human_readable_name: 'Updated Item',
          descriptive_metadata: { subject: ['Cataloging', 'Animals'] }
        )
      end

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns error' do
        expect(result.failure[:error]).to be :missing_updated_by
      end
    end
  end
end
