# frozen_string_literal: true

describe DeleteItem do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { described_class.new.call(id: item.id, deleted_by: 'initiator@example.com') }
    let(:deleted_item) { result.value![:resource] }

    context 'when the Item has no assets' do
      let(:item) { persist(:item_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'removes the Item' do
        expect {
          query_service.find_by(id: deleted_item.id)
        }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end

      it 'records event' do
        event = ResourceEvent.where(resource_identifier: deleted_item.id.to_s, event_type: :delete_item).first
        expect(event).to be_present
        expect(event).to have_attributes(resource_json: nil, initiated_by: 'initiator@example.com',
                                         completed_at: be_a(Time))
      end
    end

    context 'when the Item has assets' do
      let(:asset) { persist(:asset_resource) }
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'enqueues job to delete Assets' do
        expect(RemoveAssetJob).to have_enqueued_sidekiq_job.with(
          result.value![:resource].asset_ids.first, 'initiator@example.com'
        )
      end
    end
  end
end
