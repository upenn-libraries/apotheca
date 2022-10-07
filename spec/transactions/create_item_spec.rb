# frozen_string_literal: true

describe CreateItem do
  describe '#call' do
    include_context 'with successful EZID responses'

    let(:transaction) { described_class.new }

    context 'when all required attributes present' do
      subject(:item) { result.value! }

      let(:result) do
        transaction.call(
          human_readable_name: 'New Item',
          descriptive_metadata: { title: ['A New Item'] },
          created_by: 'admin@example.com',
          asset_ids: [asset.id]
        )
      end
      let(:asset) { persist(:asset_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'creates a new item resource' do
        expect(item).to be_a ItemResource
      end

      it 'sets attributes' do
        expect(item.human_readable_name).to eql 'New Item'
        expect(item.descriptive_metadata.title).to contain_exactly 'A New Item'
      end

      it 'sets ark' do
        expect(item.unique_identifier).not_to be_nil
      end

      it 'sets updated_by' do
        expect(item.updated_by).to eql 'admin@example.com'
      end

      it 'sets thumbnail asset id' do
        expect(item.thumbnail_asset_id).to eql asset.id
      end
    end

    context 'when missing created_by' do
      subject(:result) do
        transaction.call(
          human_readable_name: 'New Item',
          descriptive_metadata: { title: ['A New Item'] }
        )
      end

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'includes errors' do
        expect(result.failure.first).to be :validation_failed
        expect(
          result.failure.second
        ).to include(created_by: ['can\'t be blank', 'is invalid'], updated_by: ['can\'t be blank', 'is invalid'])
      end
    end
  end
end
