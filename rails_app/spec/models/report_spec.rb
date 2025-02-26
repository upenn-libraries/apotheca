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

  describe '#run' do
    let(:report) { create(:report, :queued) }

    before do
      persist(:item_resource, :with_faker_metadata)
      report.run
    end

    it 'assigns items'
    it 'generates calls build'
    it 'attaches json when successful'
    it 'raises error when failure'
  end
end
