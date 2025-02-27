# frozen_string_literal: true

# Module to add custom date fields, created_by and update_by to Valkyrie resources.
#
# TODO: update this documentation a little bit
# Because we want to track the time an Item was created in a previous or in another system, we need our own timestamp.
# Valkyrie's created_at and updated_at attributes are reserved and cannot (and should not) be modified. We added
# `first_created_at` to represent the original date of creation. `date_created` will return the original date an item
# was created regardless of what system it was first created in. `date_updated` will be an alias to Valkyrie's
# updated_at. created_by and updated_by will store the User's email that created or updated the resource.
module ModificationDetails
  extend ActiveSupport::Concern

  included do
    attribute :first_created_at, Valkyrie::Types::DateTime # Original date item was created.

    # Store the emails of the users that created and updated this item.
    attribute :created_by, Valkyrie::Types::Strict::String
    attribute :updated_by, Valkyrie::Types::Strict::String
  end

  # Aliasing date_updated to return the updated_at date.
  def date_updated
    attributes[:updated_at]
  end

  # Overriding getter method to use created_at date if a first_created_at is not set. Things added in this system and
  # not imported from another system will properly hold the time and date of creation in the `Valkyrie::Resource`
  # `created_at` attribute.
  def date_created
    attributes[:first_created_at] || created_at
  end
end
