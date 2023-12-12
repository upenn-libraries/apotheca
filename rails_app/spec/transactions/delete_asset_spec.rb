# frozen_string_literal: true

describe DeleteAsset do
  let(:transaction) { described_class.new }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { transaction.call(id: asset.id, deleted_by: 'initiator@example.com') }

    # Ensure we create item and run transaction before running any tests
    before do
      item if defined?(item)
      result
    end

    context 'when the asset is not attached to any item' do
      let(:asset) { persist(:asset_resource) }

      include_examples 'creates a resource event', :delete_asset, 'initiator@example.com', false do
        let(:resource) { asset }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'deletes asset' do
        expect { query_service.find_by(id: asset.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end

    context 'when asset is attached' do
      let(:asset) { persist(:asset_resource) }
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      include_examples 'creates a resource event', :delete_asset, 'initiator@example.com', false do
        let(:resource) { asset }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'detaches asset from parent ItemResource' do
        updated_item = query_service.find_by id: item.id # reload item to get changes in memory
        expect(updated_item.asset_ids).not_to include(asset.id)
      end

      it 'deletes asset' do
        expect { query_service.find_by(id: asset.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end

    context 'when set as thumbnail' do
      let(:item) { persist(:item_resource, :with_assets_some_arranged) }
      let(:asset) { query_service.find_by id: item.thumbnail_asset_id }

      it 'does not delete the asset and returns a descriptive error message' do
        expect(result.success?).to be false
        expect(result.failure[:error]).to include 'thumbnail'
      end
    end

    context 'when not set as thumbnail' do
      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'deletes asset' do
        expect { query_service.find_by(id: asset.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
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

      it 'detaches asset from the parent ItemResource' do
        updated_item = query_service.find_by id: item.id # reload item to get changes in memory
        expect(updated_item.asset_ids).not_to include asset.id
        expect(updated_item.structural_metadata.arranged_asset_ids).not_to include asset.id
      end
    end
  end
end
