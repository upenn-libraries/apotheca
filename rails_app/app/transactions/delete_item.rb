# frozen_string_literal: true

# Transaction that deletes an Item. All Assets attached to the Item are enqueued for deletion.
class DeleteItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_deleted_by, with: 'attributes.require_deleted_by'
  step :delete_item, with: 'item_resource.delete_resource'
  tee :record_event
  tee :delete_assets

  def record_event(resource:, deleted_by:)
    ResourceEvent.record_event_for(resource: resource, event_type: :delete_item, json: false, initiated_by: deleted_by)
  end

  # An Item can have lots of Assets, so we enqueue jobs to delete each of them here.
  # Note that Sidekiq Jobs cannot receive a Valkyrie::ID object, so we convert to string here.
  # @param [ItemResource] resource
  def delete_assets(resource:, deleted_by:)
    asset_params = resource.asset_ids&.map { |id| [id.to_s, deleted_by] }
    return if asset_params.blank?

    DeleteAssetJob.perform_bulk(asset_params)
  end
end
