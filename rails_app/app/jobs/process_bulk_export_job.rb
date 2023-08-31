# frozen_string_literal: true

# Job to perform and save a bulk export.
class ProcessBulkExportJob
  include Sidekiq::Job

  sidekiq_options queue: :medium

  def perform(bulk_export_id)
    bulk_export = BulkExport.find(bulk_export_id) # Will raise an error if missing.

    return if bulk_export.cancelled?

    bulk_export.process!
  end
end
