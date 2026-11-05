# frozen_string_literal: true

describe Resource::Steps::DeletePreservationFiles do
  let(:asset) { persist(:asset_resource, :with_image_file, :with_preservation_backup) }
  let(:result) { described_class.new.call(asset) }

  before { allow(Valkyrie::StorageAdapter).to receive(:delete).and_call_original }

  describe '#call' do
    before { result }

    it 'succeeds' do
      expect(result.success?).to be true
    end

    it 'deletes preservation files' do
      expect(Valkyrie::StorageAdapter).to have_received(:delete).with(id: asset.preservation_file_id)
    end

    it 'deletes preservation copies' do
      expect(Valkyrie::StorageAdapter).to have_received(:delete).with(id: asset.preservation_copies_ids.first)
    end
  end
end
