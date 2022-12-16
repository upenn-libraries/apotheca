# frozen_string_literal: true

# Transaction that deletes an asset.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :check_thumbnail_id # prevent deletion of Asset currently designated as a thumbnail with message
  step :unlink_from_item
  step :delete_files
  step :delete_asset, with: 'asset_resource.delete_resource'
  step :save_item, with: 'change_set.save'

  def check_thumbnail_id(resource:, item_id:)
    item_resource = query_service.find_by(id: item_id)
    # TODO: raise if item not found?
    if item_resource.thumbnail? resource.id
      Failure(error: 'This asset is currently designated as the item thumbnail. Please select a new asset to serve as the thumbnail before deleting this asset.')
    else
      Success(resource: resource, item: item_resource)
    end
  end

  # Deletes preservation and derivative files
  def delete_files(resource:, item:, **options)
    delete_file(resource.preservation_file_id) if resource.preservation_file_id.present?

    Array.wrap(resource.derivatives).each do |derivative|
      delete_file(derivative.file_id)
    end

    Array.wrap(resource.preservation_copies_ids).each do |preservation_copy_id|
      delete_file(preservation_copy_id)
    end

    Success(resource: resource, item: item, **options)
  end

  def unlink_from_item(resource:, item:)
    item_change_set = ItemChangeSet.new(item)
    item_change_set.asset_ids.delete resource.id
    item_change_set.structural_metadata.arranged_asset_ids.delete resource.id

    Success(resource: resource, item: item, change_set: item_change_set)
  end


  private

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end

  def delete_file(id)
    Valkyrie::StorageAdapter.delete(id: id)
  end
end
