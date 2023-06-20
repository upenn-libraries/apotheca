# frozen_string_literal: true

# Module to add custom date fields, created_by and update_by to Valkyrie resources.
#
# Because we want to track the time an Item was created in a previous or in another system, we need our own timestamp.
# Valkyrie's created_at and updated_at attributes are reserved and cannot (and should now) be modified. `date_created`
# will be the original date an item was created. `date_updated` will be an alias to the Valkyrie updated_at. created_by
# and updated_by will store the User's email that created or updated the resource.
module ModificationDetails
  extend ActiveSupport::Concern

  included do
    attribute :date_created, Valkyrie::Types::DateTime # Original date item was created.

    # Store the emails of the users that created and updated this item.
    attribute :created_by, Valkyrie::Types::Strict::String
    attribute :updated_by, Valkyrie::Types::Strict::String
  end

  # Aliasing date_updated to return the updated_at date.
  def date_updated
    attributes[:updated_at]
  end

  # Overriding getter method to use created_at date if a date_created is not set. Things newly added in this system and
  # not imported from another system will properly hold the time and date of creation in the `Valkyrie::Resource`
  # `created_at` attribute.
  def date_created
    attributes[:date_created] || created_at
  end
end
