# frozen_string_literal: true

# job to perform and save a bulk export
class ProcessBulkExportJob < ApplicationJob
  queue_as :default

  def perform(bulk_export)
    return if bulk_export.cancelled?

    bulk_export.process!
  end
end
