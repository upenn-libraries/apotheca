# frozen_string_literal: true

describe ImportService::Process::Invalid do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :invalid }
  end

  describe '#valid?' do
    it 'requires valid action' do
      process = build(:import_process, :invalid)
      expect(process.valid?).to be false
      expect(process.errors).to include('"invalid" is not a valid import action')
    end
  end
end
