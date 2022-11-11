# frozen_string_literal: true

class CreateAsset
  include Dry::Transaction(container: Container)

  step :create_change_set, with: 'asset_resource.create_change_set'
  step :set_updated_by, with: 'change_set.set_updated_by'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
end
