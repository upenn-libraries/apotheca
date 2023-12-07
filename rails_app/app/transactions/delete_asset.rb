# frozen_string_literal: true

# Transaction that deletes an asset, but keeps its history.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_deleted_by, with: 'attributes.require_deleted_by'
  step :find_parent_item, with: 'asset_resource.find_asset_parent_item'
  step :detach_from_item, with: 'asset_resource.detach_from_item'
  step :delete_files, with: 'asset_resource.delete_files'
  step :delete_asset, with: 'asset_resource.delete_resource'
  tee :record_event

  def record_event(resource:, deleted_by:)
    ResourceEvent.record_event_for(resource: resource, event_type: :delete_asset, json: false, initiated_by: deleted_by)
  end
end
