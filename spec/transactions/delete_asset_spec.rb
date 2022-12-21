# frozen_string_literal: true

describe DeleteAsset do
  let(:transaction) { described_class.new }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { transaction.call(id: asset.id) }

    context 'when the asset is not attached to any item' do
      let(:asset) { persist(:asset_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end
    end

    context 'when files are not attached' do
      let(:asset) { persist(:asset_resource) }
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'deletes asset' do
        expect do
          query_service.find_by(id: result.value![:resource].id)
        end.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end

    context 'when files attached' do
      context 'when set as thumbnail' do # TODO: Rubocop says too much nesting...
        let(:item) do
          persist(:item_resource, :with_assets_some_arranged)
        end

        let(:asset) do
          query_service.find_by id: item.asset_ids.first
        end

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

        it 'deletes asset' do
          expect do
            query_service.find_by(id: result.value![:resource].id)
          end.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        end

        it 'deletes preservation file' do
          expect do
            Valkyrie::StorageAdapter.find_by(id: result.value![:resource].preservation_file_id)
          end.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
        end

        it 'deletes preservation copy' do
          expect do
            Valkyrie::StorageAdapter.find_by(id: result.value![:resource].preservation_copies_ids.first)
          end.to raise_error(Valkyrie::StorageAdapter::FileNotFound)
        end

        it 'is unlinked from the parent ItemResource' do
          item_id = item.id # ensure item is instantiated before determining result
          deleted_asset_id = result.value![:resource].id
          reloaded_item = query_service.find_by id: item_id # reload item to get changes in memory
          expect(reloaded_item.asset_ids).not_to include deleted_asset_id
          expect(reloaded_item.structural_metadata.arranged_asset_ids).not_to include deleted_asset_id
        end
      end
    end
  end
end
