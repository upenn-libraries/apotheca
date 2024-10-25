# frozen_string_literal: true

module Steps
  # Deletes derivatives associated with a Resource
  class DeleteDerivatives
    include Dry::Monads[:result]

    def call(resource:, **arguments)
      Array.wrap(resource.derivatives).each do |derivative|
        delete_file(derivative.file_id)
      end
      Success(resource: resource, **arguments)
    end

    private

    # @param [Valkyrie::Types::ID] id
    def delete_file(id)
      Valkyrie::StorageAdapter.delete(id: id)
    end
  end
end
