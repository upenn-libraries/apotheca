# frozen_string_literal: true

# Transaction that creates an item with the given attributes.
class CreateItem
  include Dry::Transaction(container: Container)

  step :create_change_set, with: 'item_resource.create_change_set'
  step :set_ark
  step :set_thumbnail, with: 'item_resource.set_thumbnail'
  step :set_updated_by, with: 'change_set.set_updated_by'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :enqueue_ark_metadata_update, with: 'item_resource.enqueue_ark_metadata_update'

  private

  def set_ark(change_set)
    if change_set.unique_identifier.blank?
      ark = Ezid::Identifier.mint.to_s
      change_set.unique_identifier = ark
    end

    Success(change_set)
  end
end
