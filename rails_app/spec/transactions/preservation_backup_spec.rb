# frozen_string_literal: true

describe PreservationBackup do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:result) { transaction.call(id: asset.id, updated_by: 'initiator@example.com') }

    context 'when preservation file already backed up' do
      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup) }

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :file_backup_already_present
      end
    end

    context 'when preservation file is not backed up' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }

      include_examples 'creates a resource event', :preservation_backup, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'generates and adds preservation backup' do
        expect(updated_asset.preservation_copies_ids.length).to be 1
        expect(
          Valkyrie::StorageAdapter.find_by(id: updated_asset.preservation_copies_ids.first)
        ).to be_a Valkyrie::StorageAdapter::File
      end

      it 'mirrors preservation filename' do
        preservation_filename = updated_asset.preservation_file_id.id.split('://').last
        preservation_copy_filename = updated_asset.preservation_copies_ids.first.id.split('://').last
        expect(preservation_copy_filename).to eql preservation_filename
      end
    end

    context 'when preservation backup fails' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }

      before do
        step_double = instance_double(Steps::Validate)
        allow(Steps::Validate).to receive(:new).and_return(step_double)
        allow(step_double).to receive(:call) do |change_set|
          Dry::Monads::Failure.new(error: :step_failed, change_set: change_set)
        end
      end

      it 'cleans up the uploaded file' do
        expect(result.failure[:change_set].preservation_copies_ids.first).not_to be_nil
        expect {
          Valkyrie::StorageAdapter.find_by(id: result.failure[:change_set].preservation_copies_ids.first)
        }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end
    end
  end
end
