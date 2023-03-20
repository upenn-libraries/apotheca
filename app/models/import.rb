# frozen_string_literal: true

# Model for an asynchronous item import.
class Import < ApplicationRecord
  include Queueable

  belongs_to :bulk_import

  validates :import_data, presence: true

  # This method will run the import and set the status of the import to a success or failure.
  def run
    raise '#run still needs to be implemented'
  end

  # Determine if a user can cancel an import
  def can_cancel?(user)
    Ability.new(user).can?(:cancel, self) && self.may_cancel?
  end
end
