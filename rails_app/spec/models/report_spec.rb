# frozen_string_literal

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
end
