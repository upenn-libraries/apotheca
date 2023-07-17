# frozen_string_literal: true

describe Steps::SetThumbnail do
  let(:set_thumbnail) { described_class.new }
  let(:asset1) { persist(:asset_resource) }
  let(:asset2) { persist(:asset_resource) }
  let(:change_set) do
    change_set = ItemChangeSet.new(ItemResource.new)
    change_set.asset_ids = [asset1.id, asset2.id]
    change_set
  end

  describe '#call' do
    subject(:result) { set_thumbnail.call(change_set) }

    context 'when thumbnail is already set' do
      before do
        change_set.thumbnail_asset_id = asset2.id
      end

      it 'does not change thumbnail_asset_id' do
        expect(result.value!.thumbnail_asset_id).to eq asset2.id
      end
    end

    context 'when assets present' do
      it 'sets thumbnail_asset_id to first asset' do
        expect(result.value!.thumbnail_asset_id).to eq asset1.id
      end
    end

    context 'when arranged assets present' do
      before do
        change_set.structural_metadata.arranged_asset_ids = [asset2.id, asset1.id]
      end

      it 'sets thumbnail_asset_id to first arranged asset' do
        expect(result.value!.thumbnail_asset_id).to eq asset2.id
      end
    end
  end
end
