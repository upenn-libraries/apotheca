class ProcessBulkExportJob < ApplicationJob
  queue_as :default

  def perform(bulk_export)
    return if bulk_export.cancelled?

    bulk_export.process!
  end
end
