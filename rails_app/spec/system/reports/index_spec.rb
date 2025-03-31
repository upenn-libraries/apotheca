# frozen_string_literal: true

require 'system_helper'

describe 'Report Index Page' do
  let(:user) { create(:user, :viewer) }
  let(:reports) { [] }

  context 'when viewing reports' do
    let(:successful_report) { create(:report, :successful) }
    let(:failed_report) { create(:report, :failed) }
    let(:reports) { [successful_report, failed_report] }

    before do
      sign_in user
      reports
      visit reports_path
    end

    it 'creates a table row for each report' do
      within('#reports tbody') do
        rows = all('tr')
        expect(rows.size).to eq(reports.size)
      end
    end

    it 'lists the most recently updated reports first' do
      within('#reports tbody') do
        rows = all('tr')
        expect(reports.last.updated_at).to be > reports.first.updated_at
        expect(rows.first).to have_content(reports.last.state.titleize)
      end
    end

    it 'lists the least recently updated reports last' do
      within('#reports tbody') do
        rows = all('tr')
        expect(reports.first.updated_at).to be < reports.last.updated_at
        expect(rows.last).to have_content(reports.first.state.titleize)
      end
    end

    it 'links to the report file' do
      within('#reports tbody') do
        successful_tr = all('tr').last
        expect(successful_tr).to have_link(successful_report.file.filename.to_s,
                                           href: %r{/rails/active_storage/blobs})
      end
    end

    it 'displays the report_type' do
      within('#reports tbody') do
        tr_elements = all('tr')
        expect(tr_elements.first).to have_content(reports.last.report_type.to_s.titleize)
        expect(tr_elements.last).to have_content(reports.first.report_type.to_s.titleize)
      end
    end

    it 'displays the generated_at date' do
      within('#reports tbody') do
        tr_elements = all('tr')
        expect(tr_elements.last).to have_content(reports.first.generated_at.to_fs(:display))
      end
    end

    it 'lists the number of errors' do
      within('#reports tbody') do
        tr_elements = all('tr')
        expect(tr_elements.last).to have_content(reports.last.process_errors.size.to_s)
      end
    end
  end
end
