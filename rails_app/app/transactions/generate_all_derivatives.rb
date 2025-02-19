# frozen_string_literal: true
#
# Transaction to regenerate derivatives for all of an Item's child Assets and then optionally
# republishing the Item. A republish will only occur if the Item has been previously published.
# Publishing the item will generate the item-level derivatives.
class GenerateAllDerivatives
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :generate_all_asset_derivatives
  tee :republish

  def generate_all_asset_derivatives(resource:, updated_by:, republish: true)
    generate_derivatives = GenerateDerivatives.new

    resource.asset_ids.each do |asset_id|
      result = generate_derivatives.call(id: asset_id.to_s, updated_by: updated_by)

      return result if result.failure?
    end

    Success(resource: resource, updated_by: updated_by, republish: republish)
  end

  def republish(resource:, updated_by:, republish:)
    return unless republish && resource.published

    PublishItemJob.perform_async(resource.id.to_s, updated_by)
  end
end
