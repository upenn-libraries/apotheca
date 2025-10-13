# frozen_string_literal: true

RSpec.describe PostgresQueries::PreservationBackup do
  subject(:query) { described_class.new query_service: query_service }

  let(:query_service) do
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
  let(:asset_with_pres_backup) { persist(:asset_resource, :with_image_file, :with_preservation_backup) }
  let(:asset_without_pres_backup) { persist(:asset_resource, :with_image_file) }

  describe '#missing_preservation_backup' do
    context 'when no assets backed up' do
      before do
        persist(:item_resource, asset_ids: [asset_with_pres_backup.id])
      end

      it 'returns 0 AssetResources' do
        expect(query.missing_preservation_backup.count).to be 0
      end
    end

    context 'when one asset backed up' do
      before do
        persist(:item_resource, asset_ids: [asset_with_pres_backup.id, asset_without_pres_backup.id])
      end

      it 'returns 1 AssetResource' do
        expect(query.missing_preservation_backup.count).to be 1
        expect(query.missing_preservation_backup.first).to be_a AssetResource
      end

      it 'returns expected assets' do
        expect(query.missing_preservation_backup.first.id).to eq asset_without_pres_backup.id
      end
    end
  end

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
