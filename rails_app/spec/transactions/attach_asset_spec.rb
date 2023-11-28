# frozen_string_literal: true

describe AttachAsset do
  describe '#call' do
    subject(:updated_item) { result.value! }

    let(:transaction) { described_class.new }
    let(:asset) { persist(:asset_resource) }
    let(:result) { transaction.call(id: item.id, asset_id: asset.id, updated_by: 'admin@example.com') }

    context 'when item has no current assets' do
      let(:item) { persist(:item_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'adds id to asset_ids' do
        expect(updated_item.asset_ids).to contain_exactly(asset.id)
      end

      it 'does not add to arranged_asset_ids' do
        expect(updated_item.structural_metadata.arranged_asset_ids).to be_blank
      end

      it 'sets thumbnail' do
        expect(updated_item.thumbnail_asset_id).to eql asset.id
      end
    end

    context 'when item already has assets' do
      let(:item) { persist(:item_resource, :with_assets_some_arranged) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'adds id to asset ids' do
        expect(updated_item.asset_ids.length).to be 3
        expect(updated_item.asset_ids).to contain_exactly(*item.asset_ids, asset.id)
      end

      it 'does not add to arranged_asset_ids' do
        expect(updated_item.structural_metadata.arranged_asset_ids.length).to be 1
      end

      it 'does not set thumbnail to new asset' do
        expect(updated_item.thumbnail_asset_id).to eql item.thumbnail_asset_id
      end
    end
  end
end
