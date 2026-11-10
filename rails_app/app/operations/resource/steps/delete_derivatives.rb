# frozen_string_literal: true

module Resource
  module Steps
    # Deletes derivatives in a Resource or Change Set.
    class DeleteDerivatives
      include Dry::Monads[:result]

      # @param object [Valkyrie::Resource, Valkyrie::ChangeSet]
      def call(object)
        Array.wrap(object.derivatives).each do |derivative|
          delete_file(derivative.file_id)
        end

        Success(object)
      end

      private

      # @param [Valkyrie::Types::ID] id
      def delete_file(id)
        Valkyrie::StorageAdapter.delete(id: id)
      end
    end
  end
end
