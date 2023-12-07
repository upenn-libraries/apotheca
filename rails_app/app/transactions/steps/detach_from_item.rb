# frozen_string_literal: true

module Steps
  # Deletes preservation, preservation backup and derivative files
  class DetachFromItem
    include Dry::Monads[:result]

    def call(resource:, item:, deleted_by:, **arguments)
      # Only detach if item is present.
      if item
        result = DetachAsset.new.call(id: item.id, asset_id: resource.id, updated_by: deleted_by, **arguments)
        return result if result.failure?
      end

      Success(resource: resource, deleted_by: deleted_by, **arguments)
    end
  end
end
