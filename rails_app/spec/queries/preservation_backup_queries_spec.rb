# frozen_string_literal: true

RSpec.describe PreservationBackupQueries do
  subject(:query) { described_class.new query_service: query_service }

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
  let(:asset_with_pres_backup) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup) }
  let(:asset_without_pres_backup) { persist(:asset_resource, :with_preservation_file) }

  describe '#number_with_preservation_backup' do
    context 'when no assets provided' do
      it 'returns 0' do
        expect(query.number_with_preservation_backup([])).to be 0
      end
    end

    context 'when no assets backed up' do
      let(:asset_ids) { [asset_without_pres_backup.id] }

      it 'returns 0' do
        expect(query.number_with_preservation_backup(asset_ids)).to be 0
      end
    end

    context 'when one asset backed up' do
      let(:asset_ids) { [asset_with_pres_backup.id, asset_without_pres_backup.id] }

      it 'returns 1' do
        expect(query.number_with_preservation_backup(asset_ids)).to be 1
      end
    end
  end
end
