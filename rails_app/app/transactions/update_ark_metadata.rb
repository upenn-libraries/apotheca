# frozen_string_literal: true

# Updating metadata in EZID record.
class UpdateArkMetadata
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :update_ark_metadata

  def update_ark_metadata(resource:)
    return Success(resource) if Settings.skip_ezid_metadata_update

    presenter = item_presenter(resource) # Using presenter that contains ILS metadata and resource metadata.

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

  private

  def item_presenter(resource)
    ils_metadata = resource.bibnumber? ? query_service.custom_queries.ils_metadata_for(id: resource.id) : nil
    ItemResourcePresenter.new(object: resource, ils_metadata: ils_metadata)
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end
end
