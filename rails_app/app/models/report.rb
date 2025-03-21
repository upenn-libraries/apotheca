# frozen_string_literal: true

# JSON report that will allow us to quantify the growth of the repository over time
class Report < ApplicationRecord
  include Queueable

  REPORT_TYPES = %w[repository_growth].freeze

  has_one_attached :file
  validates :generated_at, presence: true, if: -> { file.attached? }
  validates :duration, presence: true, if: -> { state == STATE_SUCCESSFUL.to_s }
  validates :report_type, inclusion: REPORT_TYPES, presence: true

  def run
    report = nil
    elapsed_time = Benchmark.realtime { report = report_service.build }
    self.generated_at = DateTime.now
    self.duration = elapsed_time
    attach_file(io: report, content_type: 'application/json')
    success!
  rescue StandardError => e
    Honeybadger.notify(e)
    cleanup!
    failure!
  end

  # @param [IO] io
  def attach_file(io:, content_type:)
    file.attach(io: io, filename: filename(content_type), content_type: content_type)
  end

  private

  # Cleanup file and set attributes to nil
  def cleanup!
    file.purge if file.attached?
    self.generated_at = nil
    self.duration = nil
  end

  # @return ActiveStorage::Filename
  def filename(content_type = 'application/json')
    # Get extension based on content_type, will return something like '.json'
    # Default to '.json' for now, as we expect this will be the initial format
    extension = Rack::Mime::MIME_TYPES.invert[content_type]
    ActiveStorage::Filename.new("#{report_type}_#{generated_at&.strftime('%Y%m%d_%H%M%S')}#{extension}")
  end

  # @return [ReportService::Base]
  def report_service
    "ReportService::#{report_type.to_s.camelize}".safe_constantize.new
  end
end
