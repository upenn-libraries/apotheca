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
  step :require_updated_by, with: 'change_set.require_updated_by'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :generate_derivatives
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'

  # @param [AssetChangeSet] change_set
  def generate_derivatives(change_set)
    return Failure(error: :missing_mime_type) unless change_set.technical_metadata.mime_type

    file = preservation_storage.find_by id: change_set.preservation_file_id
    change_set.derivatives = derivatives_for file: file, change_set: change_set
    Success(change_set)
  rescue StandardError => e
    Failure(error: :error_generating_derivative, exception: e)
  end

  private

  # @return [Array]
  def derivative_types
    AssetChangeSet::AssetDerivativeChangeSet::TYPES
  end

  # @param [Valkyrie::StorageAdapter::StreamFile] file
  # @param [AssetChangeSet] change_set
  def derivatives_for(file:, change_set:)
    derivative_types.filter_map do |type|
      generator = DerivativeService::Generator.for(file, change_set.technical_metadata.mime_type)
      derivative_file = generator.send(type)
      next unless derivative_file # Skip, if no derivative was generated.

      file_resource = upload_resource file: derivative_file, type: type, resource: change_set.resource
      derivative_file.cleanup!
      DerivativeResource.new(file_id: file_resource.id,
                             mime_type: derivative_file.mime_type,
                             type: type, generated_at: DateTime.current)
    end
  end

  # @return [Valkyrie::StorageAdapter]
  # @param [DerivativeService::DerivativeFile] file
  def adapter_for(file:)
    file.iiif ? iiif_derivative_storage : derivative_storage
  end

  # @param [DerivativeService::DerivativeFile] file
  # @param [String] type
  # @param [Valkyrie::Resource] resource
  # @return [Object]
  def upload_resource(file:, type:, resource:)
    adapter_for(file: file).upload(
      file: file,
      resource: resource,
      original_filename: type,
      content_type: file.mime_type
    )
  end

  # @return [Valkyrie::StorageAdapter]
  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end

  # @return [Valkyrie::StorageAdapter]
  def derivative_storage
    Valkyrie::StorageAdapter.find(:derivatives)
  end

  # @return [Valkyrie::StorageAdapter]
  def iiif_derivative_storage
    Valkyrie::StorageAdapter.find(:iiif_derivatives)
  end
end
