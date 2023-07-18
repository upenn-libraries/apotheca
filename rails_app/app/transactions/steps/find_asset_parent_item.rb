# frozen_string_literal: true

module Steps
  # Finds single parent Item for an Asset, if present.
  class FindAssetParentItem
    include Dry::Monads[:result]

    def call(resource:, **attributes)
      items = query_service.find_inverse_references_by(resource: resource, property: :asset_ids)
      return Failure(error: :multiple_parent_items_found) if items.count > 1

      Success(asset: resource, item: items.try(:first), **attributes)
    end

    private

    def query_service
      Valkyrie::MetadataAdapter.find(:postgres).query_service
    end
  end
end
