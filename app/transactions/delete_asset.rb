# frozen_string_literal: true

# Transaction that deletes an asset.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :find_parent_item, with: 'asset_resource.find_asset_parent_item'
  step :check_thumbnail_id
  step :unlink_from_item_and_save
  step :delete_files
  step :delete_asset, with: 'asset_resource.delete_resource'

  # prevent deletion of Asset currently designated as a thumbnail with message
  def check_thumbnail_id(asset:, item:)
    return Success(asset: asset, item: nil) unless item # move along if no item is provided

    if item.thumbnail?(asset.id) && item.asset_ids.count > 1
      Failure(error: 'This asset is currently designated as the item thumbnail. Please select a new asset to serve as the thumbnail before deleting this asset.')
    else
      Success(asset: asset, item: item)
    end
  end

  def unlink_from_item_and_save(asset:, item:)
    return Success(asset: asset) unless item # move along if no item is provided

    item_change_set = ItemChangeSet.new(item)
    item_change_set.asset_ids.delete asset.id
    item_change_set.structural_metadata.arranged_asset_ids.delete asset.id
    # remove thumbnail if final asset is deleted
    item_change_set.thumbnail_asset_id = nil if item_change_set.asset_ids.empty?
    updated_item = item_change_set.sync

    begin
      _saved_resource = persister.save(resource: updated_item)
      Success(asset: asset)
    rescue StandardError => e
      Failure(error: :error_unlinking_asset_from_item, exception: e)
    end
  end

  # Deletes preservation and derivative files
  def delete_files(asset:)
    delete_file(asset.preservation_file_id) if asset.preservation_file_id.present?

    Array.wrap(asset.derivatives).each do |derivative|
      delete_file(derivative.file_id)
    end

    Array.wrap(asset.preservation_copies_ids).each do |preservation_copy_id|
      delete_file(preservation_copy_id)
    end

    Success(resource: asset)
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
