# frozen_string_literal: true
class BulkExport < ApplicationRecord
  include Queueable

  belongs_to :user

  validates :solr_params, presence: true
  validates :state, presence: true
  validate :restrict_number_of_bulk_exports

  def run
    raise '#run still needs to be implemented'
  end

  private

  def restrict_number_of_bulk_exports
    errors.add(:user, 'The number of Bulk Exports for a user cannot exceed 10.') if user.bulk_exports.count >= 10
  end
end
