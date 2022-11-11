# frozen_string_literal: true

# Transaction that generates derivatives for an asset.
#
# This transaction regenerates derivatives for Assets even if they aren't stale. If you only want to
# generate derivatives if they are stale, check the stale variable on derivatives before
# calling this transaction.
#
# Note: We are regenerating derivatives in the same location in storage as the previous derivatives. If derivative
# generation were to fail, we don't want to delete the derivatives that other resources are pointing to.
class GenerateDerivatives
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :generate_derivatives
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'

  def generate_derivatives(change_set)
    Failure(error: :missing_mime_type) unless change_set.technical_metadata.mime_type

    file = preservation_storage.find_by(id: change_set.preservation_file_id)

    generator = DerivativeService::Generator.for(file, change_set.technical_metadata.mime_type)
    derivative_storage = Valkyrie::StorageAdapter.find(:derivatives)

    new_derivatives = AssetChangeSet::AssetDerivativeChangeSet::TYPES.filter_map do |type|
      derivative_file = generator.send(type)
      next unless derivative_file # Skip, if no derivative was generated.

      file_resource = derivative_storage.upload(
        file: derivative_file,
        resource: change_set.resource,
        original_filename: type,
        content_type: derivative_file.mime_type
      )

      derivative_file.cleanup!

      DerivativeResource.new(
        file_id: file_resource.id,
        mime_type: derivative_file.mime_type,
        type: type, generated_at: DateTime.current
      )
    end

    change_set.derivatives = new_derivatives

    Success(change_set)
  end

  private

  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end
end
