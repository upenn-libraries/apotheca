# frozen_string_literal: true

# Transaction that deletes an asset.
#
# Note: Currently, this task does not remove any references Items might have to this asset.
class DeleteAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :delete_asset, with: 'asset_resource.delete_resource'
end
