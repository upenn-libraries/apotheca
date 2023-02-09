# frozen_string_literal: true
class BulkExport < ApplicationRecord
  include Queueable

  belongs_to :user

  has_one_attached :csv

  validates :solr_params, presence: true
  validates :state, presence: true
  validates :generated_at, presence: true, if: -> { csv.attached? }
  validate :restrict_number_of_bulk_exports

  def run
    csv_file = nil
    benchmark = Benchmark.measure do
      items = solr_items
      raise StandardError, 'No search results returned, cannot generate csv' if items.empty?

      csv_file = bulk_export_csv(items: items, include_assets: include_assets)
    end
    self.generated_at = DateTime.now
    self.duration = benchmark.total * 1000
    attach_csv_to_record(csv_file)
    success!
  rescue StandardError => e
    self.process_errors = [e.message] # TODO: this error also needs to be sent to HoneyBadger
    csv.purge if csv.attached?
    failure!
  end

  private

  def restrict_number_of_bulk_exports
    if user.present? && (user.bulk_exports.count >= 10)
      errors.add(:user, 'The number of Bulk Exports for a user cannot exceed 10.')
    end
  end

  def solr_items
    container = Valkyrie::MetadataAdapter.find(:index_solr)
                                         .query_service
                                         .custom_queries
                                         .item_index parameters: JSON.parse(solr_params).with_indifferent_access
    container.documents
  end

  # @param [Array<ItemResource>] items
  # @param [Boolean] include_assets
  # @return StringIO
  def bulk_export_csv(items:, include_assets:)
    data = items.map do |item|
      item.to_export(include_assets: include_assets)
    end
    string = StructuredCSV.generate(data)
    StringIO.new(string)
  end

  # @return ActiveStorage::Filename
  def sanitized_filename
    timestamp = generated_at.strftime('%Y%m%d_%H%M%S')
    filename = "#{title ? "#{title}_#{timestamp}" : timestamp.to_s}.csv"
    ActiveStorage::Filename.new(filename).sanitized
  end

  # @param [StringIO] csv_file
  def attach_csv_to_record(csv_file)
    csv.attach(io: csv_file, filename: sanitized_filename, content_type: 'text/csv')
  end
end
