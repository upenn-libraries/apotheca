# frozen_string_literal: true

# Transaction that deletes an asset.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_deleted_by, with: 'attributes.require_deleted_by'
  step :find_parent_item, with: 'asset_resource.find_asset_parent_item'
  step :detach_from_item
  step :delete_files
  step :delete_asset, with: 'asset_resource.delete_resource'
  tee :record_event

  def detach_from_item(resource:, item:, deleted_by:, **arguments)
    # Only detach if item is present.
    if item
      result = DetachAsset.new.call(id: item.id, asset_id: resource.id, updated_by: deleted_by, **arguments)
      return result if result.failure?
    end

    Success(resource: resource, deleted_by: deleted_by, **arguments)
  end

  # Deletes preservation and derivative files
  def delete_files(resource:, **arguments)
    delete_file(resource.preservation_file_id) if resource.preservation_file_id.present?

    Array.wrap(resource.derivatives).each do |derivative|
      delete_file(derivative.file_id)
    end

    Array.wrap(resource.preservation_copies_ids).each do |preservation_copy_id|
      delete_file(preservation_copy_id)
    end

    Success(resource: resource, **arguments)
  end

  def record_event(resource:, deleted_by:)
    ResourceEvent.record_event_for(resource: resource, event_type: :delete_asset, json: false, initiated_by: deleted_by)
  end

  private

  def persister
    Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  def delete_file(id)
    Valkyrie::StorageAdapter.delete(id: id)
  end
end
