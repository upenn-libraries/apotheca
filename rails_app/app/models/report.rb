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

  # @param [IO] io
  def attach_file(io:, content_type:)
    file.attach(io: io, filename: filename(content_type), content_type: content_type)
  end

  private

  # @return ActiveStorage::Filename
  def filename(content_type = 'application/json')
    # Get extension based on content_type, will return something like '.json'
    # Default to '.json' for now, as we expect this will be the initial format
    extension = Rack::Mime::MIME_TYPES.invert[content_type]
    ActiveStorage::Filename.new("#{report_type}_#{generated_at&.strftime('%Y%m%d_%H%M%S')}#{extension}")
  end
end
