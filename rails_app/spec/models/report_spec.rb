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
      persist(:item_resource, :with_faker_metadata, :with_full_asset)
      report.run
    end

    it 'calls build'

    context 'when successful' do
      it 'assigns generated_at'
      it 'assigns duration'
      it 'attaches json'
    end

    context 'when failure' do
      it 'raises error'
    end
  end
end
