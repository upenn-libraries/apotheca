# frozen_string_literal: true

# Transaction to regenerate IIIF manifests for an item.
class GenerateIIIFManifests
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :generate_iiif_manifest, with: 'item_resource.generate_iiif_manifests'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :generate_derivatives, json: false)
  end
end
