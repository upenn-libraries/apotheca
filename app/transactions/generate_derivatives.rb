# frozen_string_literal: true

# Transaction that generates derivatives for an asset.
#
# This transaction regenerates derivatives for Assets even if they aren't stale. If you only want to
# generate derivatives if they are stale, check the stale variable on derivatives before
# calling this transaction.
class GenerateDerivatives
  include Dry::Transaction(container: Container)

  # TODO: We should delete derivatives from storage layer if cannot save. The problem is
  #       that doing that would delete the current derivative because the new derivatives
  #       will have the same name as the old ones.
  # TODO: Should we require updated_by?
  step :find_asset, with: 'asset_resource.find_resource'
  step :create_change_set, with: 'asset_resource.create_change_set'
  # around :cleanup_derivative_files
  step :generate_derivatives
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'

  def generate_derivatives(change_set)
    Failure(:missing_mime_type) unless change_set.technical_metadata.mime_type

    file = preservation_storage.find_by(id: change_set.preservation_file_id)

    generator = DerivativeService::Generator.for(file, change_set.technical_metadata.mime_type)
    derivative_storage = Valkyrie::StorageAdapter.find(:derivatives)

    AssetChangeSet::AssetDerivativeChangeSet::TYPES.each do |type|
      derivative_file = generator.send(type)
      next unless derivative_file # Skip, if no derivative was generated.

      file_resource = derivative_storage.upload(
        file: derivative_file,
        resource: change_set.resource,
        original_filename: type,
        content_type: derivative_file.mime_type
      )
      change_set.derivatives << DerivativeResource.new(file_id: file_resource.id, mime_type: derivative_file.mime_type, type: type, generated_at: DateTime.current)

      derivative_file.cleanup!
    end

    Success(change_set)
  end

  private

  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end
end
