# frozen_string_literal: true

# Model for an asynchronous item import.
class Import < ApplicationRecord
  include Queueable

  belongs_to :bulk_import

  validates :import_data, presence: true

  # This method will run the import and set the status of the import to a success or failure.
  def run
    result = nil
    benchmark = Benchmark.measure do
      result = ImportService::Process.build(imported_by: bulk_import.created_by.email, **import_data).run
    end
    if result.success?
      self.duration = benchmark.total
      success!
    else
      self.process_errors = result.failure[:details]
      failure!
    end
  end

  # Determine if a user can cancel an import
  def can_cancel?(user)
    Ability.new(user).can?(:cancel, self) && self.may_cancel?
  end
end
