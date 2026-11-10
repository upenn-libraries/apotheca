# frozen_string_literal: true

module Asset
  module Steps
    # Find an asset's parent item, returning nil if none is set.
    class FindParentItem
      include Dry::Monads[:result]

      # @param asset [AssetResource, nil]
      def call(asset)
        items = Query.postgres.find_inverse_references_by(resource: asset, property: :asset_ids)
        return Failure(error: :multiple_parent_items_found) if items.count > 1

        Success(items.try(:first))
      end
    end
  end
end
