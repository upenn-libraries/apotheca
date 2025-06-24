# frozen_string_literal: true

shared_examples_for 'a ImportService::Process::Base' do
  before do
    raise 'import action must be set with `let(:import_action)`' unless defined? import_action
  end

  describe '#valid?' do
    it 'requires imported_by' do
      process = build(:import_process, import_action, imported_by: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include 'imported_by must always be provided'
    end

    context 'with malformed bibnumber' do
      it 'adds error' do
        process = build(:import_process, :create,
                        metadata: { 'bibnumber' => [{ value: '123456789' }] })
        expect(process.valid?).to be false
        expect(process.errors).to include('failed to retrieve marmite metadata: bibnumber must be valid')
      end
    end

    context 'when marmite fails to retrieve metadata when provided properly formatted bibnumber' do
      include_context 'with unsuccessful Marmite request'

      it 'adds error' do
        process = build(:import_process, :create,
                        metadata: { 'bibnumber' => [{ value: MMSIDValidator::EXAMPLE_VALID_MMS_ID }] })
        expect(process.valid?).to be false
        expect(process.errors).to include('failed to retrieve marmite metadata: bibnumber must be valid')
      end
    end
  end
end
