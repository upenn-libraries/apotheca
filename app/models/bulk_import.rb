# frozen_string_literal: true

# Model for BulkImport
class BulkImport < ApplicationRecord
  COMPLETED = 'completed'
  COMPLETED_WITH_ERRORS = 'completed with errors'
  IN_PROGRESS = 'in progress'
  QUEUED = 'queued'
  CANCELLED = 'cancelled'

  belongs_to :created_by, class_name: 'User'
  has_many :imports, dependent: :destroy

  validates_associated :created_by, :imports

  validates :original_filename, presence: true

  scope :filter_created_by, ->(query) { joins(:created_by).where({ created_by: { email: query } }) }
  scope :filter_created_between, lambda { |start_date, end_date|
    if start_date.present? && end_date.present?
      where(created_at: start_date..end_date)
    elsif start_date.present?
      where("created_at >= ?", start_date)
    elsif end_date.present?
      where("created_at <= ?", end_date)
    else
      all
    end
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

  # @return [StringIO]
  def csv
    data = imports.map(&:import_data)
    StructuredCSV.generate(data)
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
