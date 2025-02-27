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

    it 'calls build'

    context 'when successful' do
      before do
        persist(:item_resource, :with_faker_metadata, :with_full_asset)
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

      # TODO: maybe do a json parse and check for a few attributes (has_attributes)
      it 'attaches file with the expected data' do
        expect(report.file.download).to eq ReportService::RepositoryGrowth.new.build.read
      end

      it 'changes state to successful' do
        expect(report.state).to eq described_class::STATE_SUCCESSFUL.to_s
      end
    end

    context 'when an error is raised' do
      before do
        allow(report).to receive(:attach_file).and_raise(StandardError.new)
        report.run
      end

      it 'changes state to failed' do
        expect(report.state).to eq described_class::STATE_FAILED.to_s
      end
    end
  end
end
