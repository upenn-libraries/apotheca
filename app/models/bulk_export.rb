# frozen_string_literal: true
class BulkExport < ApplicationRecord
  include Queueable

  belongs_to :user

  has_one_attached :csv

  validates :solr_params, presence: true
  validates :state, presence: true
  validate :restrict_number_of_bulk_exports

  def generate
    process!
  end

  def run
    start_time = current_monotonic_time
    items =  solr_items
    csv_file = bulk_export_csv(items)
    self.duration = calculate_duration(start_time)
    attach_csv_to_record(csv_file)
    success!
  rescue StandardError
    csv.purge
    failure!
  end

  private

  def restrict_number_of_bulk_exports
    if user.present? && (user.bulk_exports.count >= 10)
      errors.add(:user, 'The number of Bulk Exports for a user cannot exceed 10.')
    end
  end

  def solr_query
    ItemIndex.new(query_service: Valkyrie::MetadataAdapter.find(:index_solr).query_service)
  end

  def solr_query_response
    solr_query.item_index(parameters: solr_params)
  end

  def solr_items
    solr_query_response.documents
  end

  # @param [Array<ItemResource>] items
  # @return [Array<Hash>]
  def csv_data(items)
    items.map(&:to_export)
  end

  # @param [Array<Hash>] csv_data
  # @return String
  def csv_string(csv_data)
    StructuredCSV.generate(csv_data)
  end

  # @param [String] csv_string
  # @return StringIO
  def create_csv_file(csv_string)
    StringIO.new(csv_string)
  end

  # @param [Array<ItemResource>] items
  # @return StringIO
  def bulk_export_csv(items)
    data = csv_data(items)
    string = csv_string(data)
    create_csv_file(string)
  end

  # @param [StringIO] csv_file
  def attach_csv_to_record(csv_file)
    csv.attach(io: csv_file, filename: "#{Time.current.strftime('%Y-%m-%d-T%H%M%S')}.csv", content_type: 'text/csv')
  end

  def current_monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  # @param [Float] start_time
  def calculate_duration(start_time)
    (current_monotonic_time - start_time) * 1000
  end
end
