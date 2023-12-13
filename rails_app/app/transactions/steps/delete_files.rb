# frozen_string_literal: true

module Steps
  # Deletes preservation, preservation backup and derivative files
  class DeleteFiles
    include Dry::Monads[:result]

    def call(resource:, **arguments)
      delete_file(resource.preservation_file_id) if resource.preservation_file_id.present?

      Array.wrap(resource.derivatives).each do |derivative|
        delete_file(derivative.file_id)
      end

      Array.wrap(resource.preservation_copies_ids).each do |preservation_copy_id|
        delete_file(preservation_copy_id)
      end

      Success(resource: resource, **arguments)
    end

    private

    def delete_file(id)
      Valkyrie::StorageAdapter.delete(id: id)
    end
  end
end
