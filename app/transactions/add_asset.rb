# frozen_string_literal: true

# Transaction to add an Asset to an Item. The asset is only added to the asset_id array, it is not ordered.
class AddAsset
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'change_set.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :set_thumbnail, with: 'item_resource.set_thumbnail'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'

  # Wrapping create change set to append asset id after change set is created.
  def create_change_set(asset_id:, **arguments)
    result = super(arguments)

    if result.success?
      change_set = result.value!
      change_set.asset_ids = (change_set.asset_ids || []).append(asset_id)

      Success(change_set)
    else
      result
    end
  end
end