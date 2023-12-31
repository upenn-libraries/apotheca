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
  end
end
