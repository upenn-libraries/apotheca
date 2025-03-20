# frozen_string_literal: true

describe PurgeAsset do
  let(:transaction) { described_class.new }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { transaction.call(id: asset.id, deleted_by: 'initiator@example.com') }

    context 'when the asset is not attached' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_preservation_backup) }

      before do
        ResourceEvent.record_event_for(resource: asset, event_type: :sample_event)
        result
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'deletes asset' do
        expect { query_service.find_by(id: asset.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end

      it 'removes all events' do
        expect(ResourceEvent.where(resource_identifier: asset.id.to_s).count).to be 0
      end

      it 'deletes preservation file' do
        expect {
          Valkyrie::StorageAdapter.find_by(id: asset.preservation_file_id)
        }.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
      end

      it 'deletes preservation copy' do
        expect {
          Valkyrie::StorageAdapter.find_by(id: asset.preservation_copies_ids.first)
        }.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
      end
    end

    context 'when asset is attached' do
      let(:asset) { persist(:asset_resource) }
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      before do
        item
        result
      end

      it 'is fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :asset_cannot_be_attached
      end
    end
  end
end
