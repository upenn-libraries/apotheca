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
      let(:bibnumber) { '123456789' }

      it 'adds error' do
        process = build(:import_process, :create, metadata: { 'bibnumber' => [{ value: bibnumber }] })
        expect(process.valid?).to be false
        expect(process.errors).to include("bibnumber #{bibnumber} is invalid or could not be found")
      end
    end

    context 'when marmite fails to retrieve metadata when provided properly formatted bibnumber' do
      include_context 'with unsuccessful Marmite request'
      let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

      it 'adds error' do
        process = build(:import_process, :create, metadata: { 'bibnumber' => [{ value: bibnumber }] })
        expect(process.valid?).to be false
        expect(process.errors).to include("bibnumber #{bibnumber} is invalid or could not be found")
      end
    end
  end
end
