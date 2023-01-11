# frozen_string_literal: true
class BulkExport < ApplicationRecord
  include Queueable

  belongs_to :user

  validates :solr_params, presence: true
  validates :state, presence: true

  def run
    raise '#run still needs to be implemented'
  end
end
