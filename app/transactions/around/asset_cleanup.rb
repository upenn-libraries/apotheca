# frozen_string_literal: true

module Around
  # Asset cleanup to remove preservation file that was not successfully linked to an Asset.
  class AssetCleanup
    include Dry::Monads[:result]

    def call(input, &block)
      result = block.(Success(input))

      if result.failure?
        change_set = result.failure.value.fetch(:change_set, nil)

        if change_set && change_set.changed?(:preservation_file_id) && change_set.preservation_file_id.present?
          preservation_storage.delete(id: change_set.preservation_file_id)
        end
      end

      result
    end

    def preservation_storage
      Valkyrie::StorageAdapter.find(:preservation)
    end
  end
end
