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
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :add_dpi # temporary step
  step :fetch_ocr_properties
  step :generate_derivatives, with: 'asset_resource.generate_derivatives'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event

  # @param change_set [AssetChangeSet]
  # @return [Dry::Monads::Result]
  def fetch_ocr_properties(change_set)
    return Success(change_set) unless image_mime_type?(change_set)

    item = find_parent_item(change_set.resource)

    change_set.ocr_strategy = item.ocr_strategy
    change_set.viewing_direction = item.structural_metadata.viewing_direction
    change_set.ocr_language = item.language_codes

    Success(change_set)
  rescue StandardError => e
    Failure(error: :error_generating_derivatives, exception: e)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :generate_derivatives)
  end

  # Temporary step so we can set the dpi if it's not already set.
  #
  # @todo This can be removed once we regenerate all the derivatives.
  def add_dpi(change_set)
    return Success(change_set) if change_set.technical_metadata.dpi.present?

    technical_metadata = FileCharacterization::Fits::Metadata.new(change_set.technical_metadata.raw)
    change_set.technical_metadata.dpi = technical_metadata.dpi

    Success(change_set)
  end

  private

  # @param resource [AssetResource]
  # @return [ItemResource]
  def find_parent_item(resource)
    Valkyrie::MetadataAdapter.find(:postgres).query_service
                             .find_inverse_references_by(resource: resource, property: :asset_ids).first
  end

  # @param change_set [AssetChangeSet]
  # @return [TrueClass, FalseClass]
  def image_mime_type?(change_set)
    change_set.resource.technical_metadata.mime_type.in?(DerivativeService::Asset::Generator::Image::VALID_MIME_TYPES)
  end
end
