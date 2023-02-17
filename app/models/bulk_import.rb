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

  def state

    return nil if imports.empty?

    if imports.all?(&:queued?)
      QUEUED
    elsif imports.all?(&:cancelled?)
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
    string = StructuredCSV.generate(data)
    StringIO.new(string)
  end

  # @return [Integer]
  def aggregate_processing_time
    imports.sum(:duration)
  end

  # @return [Integer]
  def number_of_errors
    imports.where(state: Import::STATE_FAILED).count
  end

  # Determine if the related Imports are all complete (_not_ processing or queued) and has at least one failed
  # @return [TrueClass, FalseClass]
  def imports_finished_with_failures?
    imports.exists?(state: Import::STATE_FAILED) && imports.where(state: [Import::STATE_QUEUED,
                                                                          Import::STATE_PROCESSING]).blank?
  end

  def imports_successful_or_cancelled?
    imports.all? { |import| import.cancelled? || import.successful? }
  end
end
