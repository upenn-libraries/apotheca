# frozen_string_literal: true

module Asset
  # Operation that regenerates derivatives for an asset.
  class RegenerateDerivatives < Operation
    # This transaction regenerates derivatives for Assets even if they aren't stale. If you only want to
    # generate derivatives if they are stale, check the stale variable on derivatives before
    # calling this transaction.
    #
    # Note: We are regenerating derivatives in the same location in storage as the previous derivatives. If derivative
    # generation were to fail, we don't want to delete the derivatives that other resources are pointing to.
    #
    # @param id [String] UUID of Asset
    # @param updated_by [String] email of user updating the Asset
    def call(id:, updated_by:)
      asset = step find_asset(id)
      change_set = step create_change_set(resource: asset, updated_by: updated_by)
      step configure_ocr_properties(change_set)
      step generate_derivatives(change_set)
      step validate(change_set)
      resource = step save(change_set)
      record_event(resource)
      resource
    end

    # @param resource [AssetResource]
    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :generate_derivatives, json: false)
    end

    private

    # @param resource [AssetResource]
    # @return [ItemResource]
    # @todo this can be replaced by step when it is merged
    def find_parent_item(resource)
      Query.postgres.find_inverse_references_by(resource: resource, property: :asset_ids).first
    end

    # @param change_set [AssetChangeSet]
    # @return [Dry::Monads::Result]
    def configure_ocr_properties(change_set)
      return Success(change_set) unless image_mime_type?(change_set)

      item = find_parent_item(change_set.resource)
      change_set.ocr_strategy = item.ocr_strategy
      change_set.viewing_direction = item.structural_metadata.viewing_direction
      change_set.ocr_language = item.language_codes

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_generating_derivatives, exception: e)
    end

    # @param change_set [AssetChangeSet]
    # @return [Boolean]
    def image_mime_type?(change_set)
      change_set.resource.technical_metadata.mime_type.in?(DerivativeService::Asset::Generator::Image::VALID_MIME_TYPES)
    end
  end
end
