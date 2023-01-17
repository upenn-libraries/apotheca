# frozen_string_literal: true

# Transaction that deletes an Item. All Assets attached to the Item are enqueued for deletion.
class DeleteItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :delete_item, with: 'item_resource.delete_resource'
  tee :enqueue_job_to_delete_assets

  # An Item can have lots of Assets, so we enqueue a job to delete them here.
  # Note that ActiveJob cannot receive an array of Valkyrie::ID objects, so we convert them to strings here.
  # @param [ItemResource] resource
  # @param [TrueClass, FalseClass] async
  def enqueue_job_to_delete_assets(resource:, async: true)
    asset_ids = resource.asset_ids.map(&:to_s)
    method = async ? 'perform_later' : 'perform_now'
    RemoveAllAssetsJob.send(method, asset_ids)
  end
end
