# frozen_string_literal: true

# Job to regenerate derivatives for all of an Item's child Assets and then publish the Item (which will also
# regenerate the IIIF manifest and PDF). Publish action to regenerate Item-level derivatives will
# only be run the Item has been previously published.
class GenerateAssetAndItemDerivativesJob < TransactionJob
  include Sidekiq::Job

  sidekiq_options queue: :medium

  def transaction(item_id, updated_by)
    # Retrieve Item.
    item = query_service.find_by(id: item_id)

    # @todo: Once we have Sidekiq Pro, we can convert this task to use batches.
    generate_derivatives = GenerateDerivatives.new
    item.asset_ids.each do |asset_id|
      result = generate_derivatives.call(id: asset_id.to_s, updated_by: updated_by)

      return result if result.failure?
    end

    if item.published
      result = PublishItem.new.call(id: item_id, updated_by: updated_by)

      return result if result.failure?
    end

    Dry::Monads::Success('Assets and Item Derivatives Regenerated')
  end

  private

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
