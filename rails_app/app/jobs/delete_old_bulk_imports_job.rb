# frozen_string_literal: true

# Deleting Bulk Imports that are older than 6 months.
class DeleteOldBulkImportsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  def perform
    BulkImport.where('updated_at < ?', 6.months.ago).find_each(&:destroy!)
  end
end
