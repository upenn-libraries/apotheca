# frozen_string_literal: true

# Adds or updates DPI for an asset.
class AddDPI
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :add_dpi
  step :save, with: 'change_set.save'
  tee :record_event

  def add_dpi(change_set)
    change_set.technical_metadata.dpi = technical_metadata(change_set).dpi

    Success(change_set)
  rescue StandardError => e
    Failure(error: :adding_dpi_failed, exception: e, change_set: change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :update_asset)
  end

  private

  # @return [FileCharacterization::Fits::Metadata]
  def technical_metadata(change_set)
    FileCharacterization::Fits::Metadata.new(change_set.resource.technical_metadata.raw)
  end
end
