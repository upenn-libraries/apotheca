# frozen_string_literal: true

# Updating metadata in EZID record.
class UpdateArkMetadata
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :update_ark_metadata

  def update_ark_metadata(resource:)
    return Success(resource) if Settings.ezid_metadata_update.skip

    presenter = resource.presenter # Using presenter that contains ILS metadata and resource metadata.

    dc_metadata = {
      '_profile' => 'dc',
      'dc.creator' => presenter.descriptive_metadata&.name&.pluck(:value)&.join('; '),
      'dc.title' => presenter.descriptive_metadata&.title&.pluck(:value)&.join('; '),
      'dc.publisher' => presenter.descriptive_metadata&.publisher&.pluck(:value)&.join('; '),
      'dc.date' => presenter.descriptive_metadata&.date&.pluck(:value)&.join('; '),
      'dc.type' => presenter.descriptive_metadata&.item_type&.pluck(:value)&.join('; ')
    }.compact_blank

    # NOTE: EZID library retries requests twice before raising an error.
    Ezid::Identifier.modify(resource.unique_identifier, dc_metadata)
    Success(resource)
  rescue StandardError => e
    Failure(error: :failed_to_update_ezid_metadata, exception: e)
  end
end
