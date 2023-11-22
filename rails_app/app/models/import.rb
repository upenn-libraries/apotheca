# frozen_string_literal: true

# Model for an asynchronous item import.
class Import < ApplicationRecord
  include Queueable

  belongs_to :bulk_import

  validates :import_data, presence: true

  # Run the import and set the status of the import to a success or failure
  def run
    result = nil
    elapsed_time = Benchmark.realtime do
      result = ImportService::Process.build(imported_by: bulk_import.created_by.email, **import_data).run
    end

    self.duration = elapsed_time

    if result.success?
      self.resource_identifier = result.value!.unique_identifier
      success!
    else
      error_message = result.failure[:exception].presence ||
                      "#{result.failure[:error]}: #{result.failure[:details].join('; ')}"
      Honeybadger.notify(error_message)
      self.process_errors = result.failure[:details]
      failure!
    end
  end

  # Determine if a user can cancel an import
  def can_cancel?(user)
    Ability.new(user).can?(:cancel, self) && may_cancel?
  end

  # Return human_readable_name from ItemResource if it's been assigned or from data hash if not
  def human_readable_name
    return resource.human_readable_name if resource.present?

    import_data['human_readable_name']
  end

  # Get associated Valkyrie::Resource
  # @return [Valkyrie::Resource, nil]
  def resource
    identifier = resource_identifier || import_data['unique_identifier']

    return unless identifier

    @resource ||= query_service.custom_queries.find_by_unique_identifier(unique_identifier: identifier)
  end

  private

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
