# frozen_string_literal: true

# Generate a report
class GenerateReportJob
  include Sidekiq::Job
  sidekiq_options queue: :medium

  # Default to repository growth report
  def perform(report_type)
    report = Report.create!(report_type: report_type)
    report.process!
  end
end
