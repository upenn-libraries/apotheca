# frozen_string_literal: true

# Transaction that deletes an Item. All Assets attached to the Item are enqueued for deletion.
class DeleteItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :delete_item, with: 'item_resource.delete_resource'
  tee :delete_assets

  # An Item can have lots of Assets, so we enqueue jobs to delete each of them here.
  # Note that Sidekiq Jobs cannot receive a Valkyrie::ID object, so we convert to string here.
  # @param [ItemResource] resource
  # @param [TrueClass, FalseClass] async
  def delete_assets(resource:, async: true)
    asset_ids = resource.asset_ids&.map { |id| [id.to_s] }
    return if asset_ids.blank?

    if async
      RemoveAssetJob.perform_bulk(asset_ids)
    else
      asset_ids.each do |id|
        RemoveAssetJob.perform_inline(id.first)
      end
    end
  end
end
