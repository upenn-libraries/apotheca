# frozen_string_literal: true

# Model for BulkImport
class BulkImport < ApplicationRecord
  COMPLETED = 'completed'
  COMPLETED_WITH_ERRORS = 'completed with errors'
  IN_PROGRESS = 'in progress'
  QUEUED = 'queued'
  CANCELLED = 'cancelled'

  PRIORITY_QUEUES = %w[high medium low].freeze
  DEFAULT_PRIORITY = 'medium'

  belongs_to :created_by, class_name: 'User'
  has_many :imports, dependent: :destroy

  validates_associated :created_by, :imports

  attr_accessor :csv_rows

  validates :original_filename, presence: true

  scope :filter_created_by, ->(query) { joins(:created_by).where({ created_by: { email: query } }) }
  scope :filter_created_between, lambda { |start_date, end_date|
    start_date = start_date.present? ? start_date.to_date.beginning_of_day : nil
    end_date = end_date.present? ? end_date.to_date.end_of_day : nil
    where(created_at: start_date..end_date) if start_date || end_date
  }
  scope :search, ->(query) { where("original_filename ILIKE :search OR note ILIKE :search", search: "%#{query}%") }

  paginates_per 10

  def state
    return nil if imports.empty?

    if imports_queued?
      QUEUED
    elsif imports_cancelled?
      CANCELLED
    elsif imports_successful_or_cancelled?
      COMPLETED
    elsif imports_finished_with_failures?
      COMPLETED_WITH_ERRORS
    else
      IN_PROGRESS
    end
  end

  # @param [String] queue
  def create_imports(queue = BulkImport::DEFAULT_PRIORITY)
    csv_rows.each do |row|
      import = Import.create(bulk_import: self, import_data: row)
      ProcessImportJob.set(queue: queue).perform_later(import)
    end
  end

  # @return [StringIO]
  def csv
    data = imports.map(&:import_data)
    StructuredCSV.generate(data)
  end

  # A bulk import has an empty_csv if the parsed csv cached in csv_rows contains no item data
  # @return [Boolean]
  def empty_csv?
    return true if csv_rows.blank?

    csv_rows.each do |row|
      return false if row.present?
    end
    true
  end

  # @return [Integer]
  def aggregate_processing_time
    imports.sum(:duration)
  end

  # @return [Integer]
  def number_of_errors
    imports.failed.count
  end

  # Determine if the related Imports are all queued
  # @return [TrueClass, FalseClass]
  def imports_queued?
    imports.count.positive? && imports.queued.count == imports.count
  end

  # Determine if any of the related Imports are queued
  def any_imports_queued?
    imports.exists?(state: Import::STATE_QUEUED)
  end

  # Determine if the related Imports are all cancelled
  # @return [TrueClass, FalseClass]
  def imports_cancelled?
    imports.count.positive? && imports.cancelled.count == imports.count
  end

  # Determine if the related Imports are all complete (_not_ processing or queued) and has at least one failed
  # @return [TrueClass, FalseClass]
  def imports_finished_with_failures?
    imports.exists?(state: Import::STATE_FAILED) && imports.where(state: [Import::STATE_QUEUED,
                                                                          Import::STATE_PROCESSING]).blank?
  end

  # Determine if the related Imports are all either successful or cancelled
  # @return [TrueClass, FalseClass]
  def imports_successful_or_cancelled?
    imports.count.positive? && ((imports.successful.count + imports.cancelled.count) == imports.count)
  end

  # @param [User] current_user
  # Cancel all possible child imports
  def cancel_all(current_user)
    imports.queued.each { |import| import.cancel! if import.can_cancel?(current_user) }
  end
end
