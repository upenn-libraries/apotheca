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
          preservation_storage.delete(id: change_set.preservation_file_id)
        end

        if change_set&.changed?(:preservation_copies_ids) && change_set.preservation_copies_ids.present?
          preservation_copy_storage.delete(id: change_set.preservation_copies_ids.first)
        end
      end

      result
    end

    def preservation_storage
      Valkyrie::StorageAdapter.find(:preservation)
    end

    def preservation_copy_storage
      Valkyrie::StorageAdapter.find(:preservation_copy)
    end
  end
end
