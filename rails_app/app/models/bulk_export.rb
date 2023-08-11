# frozen_string_literal: true

# A Bulk Export allows a user to export Item data as a csv
class BulkExport < ApplicationRecord
  include Queueable

  belongs_to :created_by, class_name: 'User'

  has_one_attached :csv
  validates :state, presence: true
  validates :generated_at, presence: true, if: -> { csv.attached? }
  validate :restrict_number_of_bulk_exports
  validate :restrict_search_params_to_hash

  scope :filter_created_by, ->(query) { joins(:created_by).where({ created_by: { email: query } }) }
  scope :sort_by_field, ->(field, direction) { order("#{field}": direction.to_s) }
  scope :with_created_by, -> { includes(:created_by) }

  def run
    csv_file = nil
    benchmark = Benchmark.measure do
      items = solr_items
      raise StandardError, 'No search results returned, cannot generate csv' if items.empty?

      csv_file = bulk_export_csv(items: items, include_assets: include_assets)
      self.records_count = items.length
    end
    self.generated_at = DateTime.now
    self.duration = benchmark.total
    attach_csv_to_record(csv_file)
    success!
  rescue StandardError => e
    Honeybadger.notify(e)
    self.process_errors = [e.message]

    csv.purge if csv.attached?
    failure!
  end

  def remove_values_for_display
    update(generated_at: nil, duration: nil, records_count: nil)
    csv.purge
  end

  private

  def restrict_number_of_bulk_exports
    return unless created_by.present? && (created_by.bulk_exports.count >= 10)

    errors.add(:created_by, 'The number of Bulk Exports for a user cannot exceed 10.')
  end

  def restrict_search_params_to_hash
    return if search_params.is_a?(Hash)

    errors.add(:search_params, 'must be a hash')
  end

  def solr_items
    container = Valkyrie::MetadataAdapter.find(:index_solr)
                                         .query_service
                                         .custom_queries
                                         .item_index parameters: search_params.update(rows: max_rows_to_export)
                                                                              .with_indifferent_access
    container.documents
  end

  # @param [Array<ItemResource>] items
  # @param [Boolean] include_assets
  # @return StringIO
  def bulk_export_csv(items:, include_assets:)
    data = items.map do |item|
      item.to_json_export(include_assets: include_assets)
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

  # @return [Integer]
  def max_rows_to_export
    Solr::QueryMaps::Item::MAX_BULK_EXPORT_ROWS
  end
end
