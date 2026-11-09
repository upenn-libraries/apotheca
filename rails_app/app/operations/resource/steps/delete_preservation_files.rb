# frozen_string_literal: true

module Resource
  module Steps
    # Delete all of an asset's preservation files.
    class DeletePreservationFiles
      include Dry::Monads[:result]

      # @param resource [Valkyrie::Resource]
      def call(resource)
        delete_file(resource.preservation_file_id) if resource.preservation_file_id.present?
        Array.wrap(resource.preservation_copies_ids).each do |preservation_copy_id|
          delete_file(preservation_copy_id)
        end

        Success(resource)
      end

      private

      # @param id [Valkyrie::Types::ID]
      def delete_file(id)
        Valkyrie::StorageAdapter.delete(id: id)
      end
    end
  end
end
