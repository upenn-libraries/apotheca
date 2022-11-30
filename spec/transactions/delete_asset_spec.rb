# frozen_string_literal: true

describe DeleteAsset do
  let(:transaction) { described_class.new }

  describe '#call' do
    let(:result) { transaction.call(id: asset.id) }

    context 'when files are not attached' do
      let(:asset) { persist(:asset_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'deletes asset' do
        query_service = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service
        expect {
          query_service.find_by(id: result.value!.id)
        }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end

    context 'when files attached' do
      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup) }

      it 'deletes asset' do
        query_service = Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service
        expect {
          query_service.find_by(id: result.value!.id)
        }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it 'deletes preservation file' do
        expect {
          Valkyrie::StorageAdapter.find_by(id: result.value!.preservation_file_id)
        }.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
      end

      it 'deletes preservation copy' do
        expect {
          Valkyrie::StorageAdapter.find_by(id: result.value!.preservation_copies_ids.first)
        }.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
      end
    end
  end
end
