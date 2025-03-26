# frozen_string_literal: true

require_relative 'concerns/queueable'

describe Report do
  it_behaves_like 'queueable'

  context 'with file attached' do
    it 'requires generated_at' do
      report = build(:report, :successful, generated_at: nil)
      expect(report.valid?).to be false
      expect(report.errors['generated_at']).to include "can't be blank"
    end
  end

  context 'with a report_type' do
    it 'requires inclusion' do
      report = build(:report, report_type: 'not_valid_type')
      expect(report.valid?).to be false
      expect(report.errors['report_type']).to include 'is not included in the list'
    end
  end

  context 'with a successful state' do
    it 'requires duration' do
      report = build(:report, :successful, duration: nil)
      expect(report.valid?).to be false
      expect(report.errors['duration']).to include "can't be blank"
    end
  end

  it 'requires report_type' do
    report = build(:report, report_type: nil)
    expect(report.valid?).to be false
    expect(report.errors['report_type']).to include "can't be blank"
  end

  describe '#run' do
    let(:report) { create(:report, :processing) }
    let(:report_service) do
      instance_double("ReportService::#{report.report_type.to_s.camelize}".safe_constantize)
    end

    it 'calls #build on report service' do
      allow(report).to receive(:report_service).and_return(report_service)
      allow(report_service).to receive(:build)
      report.run
      expect(report_service).to have_received(:build)
    end

    context 'when successful' do
      let(:item) { persist(:item_resource, :with_faker_metadata, :with_full_asset) }

      before do
        item
        report.run
      end

      it 'assigns generated_at' do
        expect(report.generated_at).not_to be_nil
      end

      it 'assigns duration' do
        expect(report.duration).not_to be_nil
      end

      it 'attaches file' do
        expect(report.file).to be_attached
      end

      it 'attaches file with the expected data' do
        expect(report.file.download).to eq ReportService::RepositoryGrowth.new.build.read
      end

      it 'changes state to successful' do
        expect(report.state).to eq described_class::STATE_SUCCESSFUL.to_s
      end

      it 'assigns some attributes' do
        items = JSON.parse(report.file.download)['items']
        expect(items.first['unique_identifier']).to eq item.unique_identifier
        expect(items.first.dig('descriptive_metadata', 'title')
          .first['value']).to eq item.descriptive_metadata.title.first.value
      end
    end

    context 'when an error is raised' do
      before do
        allow(report).to receive(:attach_file).and_raise(StandardError)
        report.run
      end

      it 'changes state to failed' do
        expect(report.state).to eq described_class::STATE_FAILED.to_s
      end

      it 'does not attach the file' do
        expect(report.file).not_to be_attached
      end

      it 'resets attributes' do
        expect(report.generated_at).to be_nil
        expect(report.duration).to be_nil
      end

      it 'sets process_errors' do
        expect(report.process_errors).not_to be_empty
      end
    end
  end
end
