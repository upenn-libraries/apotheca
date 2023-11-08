# frozen_string_literal: true

describe Steps::VirusCheck do
  describe '#call' do
    let(:step) { described_class.new }
    let(:result) { step.call(file: Tempfile.new, updated_by: 'test@test.edu') }

    before do
      allow(Clamby).to receive(:safe?).with(anything).and_return(clamby_outcome)
      allow(step).to receive(:should_scan_file?).with(anything).and_return(perform_scan)
      # ignore environment setting concerning Clamby as this spec stubs Clamby method calls so can always run
      allow(step).to receive(:skip_in_environment?).and_return(false)
    end

    context 'when the file is too large' do
      let(:perform_scan) { false }
      let(:clamby_outcome) { nil }

      it 'returns success and sets a preservation message' do
        expect(result.success?).to be true
        expect(result.success[:temporary_events].first[:outcome_detail_note]).to eq(
          I18n.t('preservation_events.virus_check.unscanned')
        )
      end
    end

    context 'when there is a virus' do
      let(:perform_scan) { true }
      let(:clamby_outcome) { false }

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to eq :virus_detected
      end
    end

    context 'when there is no virus' do
      let(:perform_scan) { true }
      let(:clamby_outcome) { true }

      it 'returns success and sets a preservation message' do
        expect(result.success?).to be true
        expect(result.success[:temporary_events].first[:outcome_detail_note]).to eq(
          I18n.t('preservation_events.virus_check.clean')
        )
      end
    end

    context 'when there is a clamscan issue' do
      let(:perform_scan) { true }
      let(:clamby_outcome) { nil }

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to eq :clamscan_problem
      end
    end
  end
end
