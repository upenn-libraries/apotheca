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
  step :generate_derivatives, with: 'asset_resource.generate_derivatives'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :generate_derivatives)
  end
end
