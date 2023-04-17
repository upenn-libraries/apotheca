# frozen_string_literal: true

# Model for an asynchronous item import.
class Import < ApplicationRecord
  include Queueable

  belongs_to :bulk_import

  validates :import_data, presence: true

  # Run the import and set the status of the import to a success or failure
  def run
    result = nil
    benchmark = Benchmark.measure do
      result = ImportService::Process.build(imported_by: bulk_import.created_by.email, **import_data).run
    end
    if result.success?
      self.duration = benchmark.total
      self.resource_identifier = result.value!.unique_identifier
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

  # Return human_readable_name from ItemResource if it's been assigned or from data hash if not
  def human_readable_name
    query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
    item = query_service.custom_queries.find_by_unique_identifier(unique_identifier: resource_identifier)
    return item.human_readable_name if item

    import_data['human_readable_name']
  end
end
