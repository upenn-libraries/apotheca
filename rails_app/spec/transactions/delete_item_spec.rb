# frozen_string_literal: true

describe DeleteItem do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { described_class.new.call(id: item.id, deleted_by: 'initiator@example.com') }
    let(:deleted_item) { result.value![:resource] }

    context 'when the Item has no assets' do
      let(:item) { persist(:item_resource) }

      include_examples 'creates a resource event', :delete_item, 'initiator@example.com', false do
        let(:resource) { deleted_item }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'removes the Item' do
        expect {
          query_service.find_by(id: deleted_item.id)
        }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when the Item has assets' do
      let(:asset) { persist(:asset_resource) }
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'enqueues job to delete Assets' do
        expect(DeleteAssetJob).to have_enqueued_sidekiq_job.with(
          result.value![:resource].asset_ids.first, 'initiator@example.com'
        )
      end
    end

    context 'when the Item is published' do
      include_context 'with successful unpublish request'

      let(:item) { persist(:item_resource, :published) }

      it 'makes unpublish request' do
        result
        expect(a_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")).to have_been_made
      end
    end
  end
end
