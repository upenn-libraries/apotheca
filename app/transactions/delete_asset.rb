# frozen_string_literal: true

# Transaction that deletes an asset.
#
# Note: Currently, this task does not remove any references Items might have to this asset.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :delete_files
  step :delete_asset, with: 'asset_resource.delete_resource'

  # Deletes preservation and derivative files
  def delete_files(resource:)
    if resource.preservation_file_id.present?
      delete_file(resource.preservation_file_id)
    end

    (resource.derivatives || []).each do |derivative|
      delete_file(derivative.file_id)
    end

    (resource.preservation_copies_ids || []).each do |preservation_copy_id|
      delete_file(preservation_copy_id)
    end

    Success(resource: resource)
  end

  private

  def delete_file(id)
    Valkyrie::StorageAdapter.delete(id: id)
  end
end
