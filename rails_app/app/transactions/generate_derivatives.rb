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
  step :fetch_ocr_properties
  step :generate_derivatives, with: 'asset_resource.generate_derivatives'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event

  # @param change_set [AssetChangeSet]
  # @return [Dry::Monads::Result]
  def fetch_ocr_properties(change_set)
    mime_type = change_set.resource.technical_metadata.mime_type
    return Success(change_set) unless mime_type.in?(DerivativeService::Asset::Generator::Image::VALID_MIME_TYPES)

    item = find_parent_item(change_set.resource)
    change_set.viewing_direction = item.structural_metadata.viewing_direction
    change_set.ocr_language = ocr_language(item)

    Success(change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :generate_derivatives)
  end

  private

  # @param item [ItemResource]
  # @return [Array<String>]
  def ocr_language(item)
    language = item.descriptive_metadata.language.flat_map { |lang| ISO_639.find_by_english_name(lang.value).first(2) }
    bibnumber = item.descriptive_metadata.bibnumber

    if request_language_from_ils?(language, bibnumber)
      # get language from ils
      language = language_metadata(bibnumber).flat_map { |lang| ISO_639.find_by_english_name(lang[:value]).first(2) }
    end

    language.compact_blank
  end

  # @param language [Array]
  # @param bibnumber [String]
  # @return [TrueClass, FalseClass]
  def request_language_from_ils?(language, bibnumber)
    language.empty? && bibnumber.present?
  end

  # @param bibnumber [String]
  # @return [Array]
  def language_metadata(bibnumber)
    MetadataExtractor::Marmite.new(url: Settings.marmite.url).descriptive_metadata(bibnumber)[:language] || []
  end

  # @param resource [AssetResource]
  # @return [ItemResource]
  def find_parent_item(resource)
    Valkyrie::MetadataAdapter.find(:postgres).query_service
                             .find_inverse_references_by(resource: resource, property: :asset_ids).first
  end
end
