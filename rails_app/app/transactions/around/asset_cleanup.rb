# frozen_string_literal: true

module Around
  # Asset cleanup to remove preservation file that was not successfully linked to an Asset.
  class AssetCleanup
    include Dry::Monads[:result]

    def call(input)
      result = yield(Success(input))

      if result.failure?
        change_set = result.failure.value.fetch(:change_set, nil)

        if change_set&.changed?(:preservation_file_id) && change_set.preservation_file_id.present?
          Valkyrie::StorageAdapter.delete(id: change_set.preservation_file_id)
        end

        if change_set&.changed?(:preservation_copies_ids) && change_set.preservation_copies_ids.present?
          Valkyrie::StorageAdapter.delete(id: change_set.preservation_copies_ids.first)
        end

        delete_derivatives(change_set)
      end

      result
    end

    private

    # Only delete derivatives if originally no derivatives were present. We don't want to delete the derivatives if
    # they were already present because external systems depend on them.
    def delete_derivatives(change_set)
      return if change_set.blank? || change_set.resource&.derivatives.present?

      change_set.derivatives.each do |derivative|
        Valkyrie::StorageAdapter.delete(id: derivative.file_id)
      end
    end
  end
end
