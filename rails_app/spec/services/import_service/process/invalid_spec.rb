# frozen_string_literal: true

require_relative 'base'

describe ImportService::Process::Invalid do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :invalid }
  end

  describe '#valid?' do
    it 'requires valid action' do
      process = build(:import_process, :invalid)
      expect(process.valid?).to be false
      expect(process.errors).to contain_exactly('"invalid" is not a valid import action')
    end

    it 'returns a valid error message if action is nil' do
      process = build(:import_process, action: nil)
      expect(process.valid?).to be false
      expect(process.errors).to contain_exactly("action can't be blank")
    end
  end
end
