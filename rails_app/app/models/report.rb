# frozen_string_literal: true

# JSON report that will allow us to quantify the growth of the repository over time
class Report < ApplicationRecord
  include Queueable

  has_one_attached :file
  validates :generated_at, presence: true, if: -> { file.attached? }
  # TODO: validate report_type is in a constant REPORT_TYPES array
  # TODO: more validations potentially?
  # bulk_export validate state in the model, but that validation is already included in Queueable

  def run
    # TODO: implement run method when repository growth report details are finalized
    #
    # this method will likely call a service that generates the report given all item data
    # and send that data to the file (i think...)
    # maybe something like `result = ReportService.build(...)`
    #
    # call `success!` if everything succeeds, rescue errors and call `failure!`
  end
end
