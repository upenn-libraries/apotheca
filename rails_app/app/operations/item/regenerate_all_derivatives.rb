# frozen_string_literal: true

module Item
  # Operation that regenerate derivatives for all of an Item's child Assets and then optionally
  # republishing the Item. A republish will only occur if the Item has been previously published.
  # Publishing the item will generate the item-level derivatives.
  class RegenerateAllDerivatives < Operation
    # Executes this operation
    # @param id [String] UUID of Item
    # @param updated_by [String] email of user who initiated this operation
    # @param republish [Boolean] include a republish of the item if the item is flagged as published
    def call(id:, updated_by:, republish: true)
      @item = step find_item(id)
      @updated_by = updated_by
      step regenerate_all_asset_derivatives

      republish_later if republish && @item.published
      record_event

      @item
    end

    private

    def regenerate_all_asset_derivatives
      Array.wrap(@item.asset_ids).each do |asset_id|
        result = Asset::RegenerateDerivatives.call(asset_id.to_s, @updated_by)

        return result if result.failure?
      end

      Success()
    end

    def republish_later
      PublishItemJob.perform_async(@item.id.to_s, @updated_by)
    end

    def record_event
      ResourceEvent.record_event_for(resource: @item, event_type: :generate_all_derivatives,
                                     json: false, initiated_by: @updated_by)
    end
  end
end
