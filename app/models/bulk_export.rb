# frozen_string_literal: true
class BulkExport < ApplicationRecord
  include Queueable

  belongs_to :user

  has_one_attached :csv

  validates :solr_params, presence: true
  validates :state, presence: true
  validate :restrict_number_of_bulk_exports

  def run
    start_time = current_monotonic_time
    items = solr_items
    raise StandardError, 'No search results returned, cannot generate csv' if items.empty?

    csv_file = bulk_export_csv(items)
    self.duration = calculate_duration(start_time)
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
                                         .item_index parameters: solr_params.with_indifferent_access
    container.documents
  end

  # @param [Array<ItemResource>] items
  # @return StringIO
  def bulk_export_csv(items)
    data = items.map(&:to_export)
    string = StructuredCSV.generate(data)
    StringIO.new(string)
  end

  # @param [StringIO] csv_file
  def attach_csv_to_record(csv_file)
    csv.attach(io: csv_file, filename: "#{Time.current.strftime('%Y-%m-%d-T%H%M%S')}.csv", content_type: 'text/csv')
  end

  # @return Integer
  def current_monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
  end

  # @param [Integer] start_time
  # @return Integer
  def calculate_duration(start_time)
    (current_monotonic_time - start_time)
  end
end
