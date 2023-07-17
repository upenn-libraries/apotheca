# frozen_string_literal: true

describe PreservationBackup do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:result) { transaction.call(id: asset.id) }

    context 'when preservation file already backed up' do
      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup) }

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :file_backup_already_present
      end
    end

    context 'when preservation file is not backed up' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }

      it 'generates and adds preservation backup' do
        expect(updated_asset.preservation_copies_ids.length).to be 1
        expect(
          Valkyrie::StorageAdapter.find_by(id: updated_asset.preservation_copies_ids.first)
        ).to be_a Valkyrie::StorageAdapter::File
      end
    end
  end
end
