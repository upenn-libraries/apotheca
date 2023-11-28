# frozen_string_literal: true

# Transaction to detach an Asset from an Item. The asset is removed from assets_id and
# the arranged_asset_ids.
class DetachAsset
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'change_set.require_updated_by'
  step :check_thumbnail_id
  step :create_change_set, with: 'item_resource.create_change_set'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'

  # Prevent the detachment of Asset currently designated as a thumbnail with message.
  def check_thumbnail_id(resource:, asset_id:, **attributes)
    if resource.thumbnail?(asset_id) && resource.asset_ids.count > 1
      Failure(error: 'This asset is currently designated as the item thumbnail. Please select a new asset to serve as the thumbnail before deleting this asset.')
    else
      Success(resource: resource, asset_id: asset_id, **attributes)
    end
  end

  # Wrapping create change set to remove asset id after change set is created.
  def create_change_set(asset_id:, **arguments)
    result = super(arguments)

    if result.success?
      change_set = result.value!

      # Remove asset from asset_ids and arranged_asset_ids
      change_set.asset_ids.delete asset_id
      change_set.structural_metadata.arranged_asset_ids.delete asset_id

      # Remove thumbnail if final asset is deleted.
      change_set.thumbnail_asset_id = nil if change_set.asset_ids.empty?

      Success(change_set)
    else
      result
    end
  end
end
