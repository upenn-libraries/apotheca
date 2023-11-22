# frozen_string_literal: true

# Transaction that deletes an asset.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :find_parent_item, with: 'asset_resource.find_asset_parent_item'
  step :detach_from_item
  step :delete_files
  step :delete_asset, with: 'asset_resource.delete_resource'

  def detach_from_item(asset:, item:, **arguments)
    return Success(asset: asset) unless item # move along if no item is provided

    result = DetachAsset.new.call(id: item.id, asset_id: asset.id, **arguments)
    result.failure? ? result : Success(asset: asset)
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
