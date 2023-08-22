# frozen_string_literal: true

# Transaction that deletes an Item. All Assets attached to the Item are enqueued for deletion.
class DeleteItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :delete_item, with: 'item_resource.delete_resource'
  tee :delete_assets

  # An Item can have lots of Assets, so we enqueue jobs to delete each of them here.
  # Note that ActiveJob cannot receive a Valkyrie::ID object, so we convertto string here.
  # @param [ItemResource] resource
  # @param [TrueClass, FalseClass] async
  def delete_assets(resource:, async: true)
    method = async ? 'perform_async' : 'perform_inline'
    resource.asset_ids&.each do |asset_id|
      RemoveAssetJob.send(method, asset_id.to_s)
    end
  end
end
