# frozen_string_literal: true

# Adds `iiif_image` derivative for image Assets and removes `access` derivative.
#
# This transaction migrates the `access` derivative for image-based Assets to be the `iiif_image` derivative.
class AddIIIFImageDerivative
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :add_iiif_image_derivative
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event

  def add_iiif_image_derivative(change_set)
    return Failure(error: :asset_not_an_image) unless change_set.resource.image?
    return Failure(error: :iiif_image_derivative_already_present) if change_set.resource.iiif_image

    # Copy `access` derivative file to `iiif_image`.
    iiif_image = create_iiif_image(change_set.resource)

    # Remove `access` derivative and add `iiif_image`.
    derivatives = change_set.resource.derivatives.reject(&:access?)
    derivatives += [iiif_image]
    change_set.derivatives = derivatives

    Success(change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :generate_derivatives, json: false)
  end

  private

  # Create `iiif_image` derivative from the `access` derivative.
  #
  # @param asset [AssetResource]
  # @return [DerivativeResource]
  def create_iiif_image(asset)
    access = asset.access
    access_file = iiif_derivative_storage.find_by(id: access.file_id)

    iiif_image_file = iiif_derivative_storage.upload(
      file: access_file,
      resource: asset,
      original_filename: 'iiif_image',
      content_type: access.mime_type
    )

    DerivativeResource.new(file_id: iiif_image_file.id, mime_type: access.mime_type,
                           size: iiif_image_file.size, type: 'iiif_image', generated_at: DateTime.current)
  end

  # @return [Valkyrie::StorageAdapter]
  def iiif_derivative_storage
    Valkyrie::StorageAdapter.find(:iiif_derivatives)
  end
end
