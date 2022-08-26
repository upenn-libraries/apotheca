# frozen_string_literal: true

shared_examples_for 'ModificationDetails' do |factory|
  describe '#date_created' do
    context 'when date_created is set' do
      let(:date_created) { DateTime.new(2000, 2, 1) }
      let(:resource) { persist(factory, date_created: date_created) }

      it 'returns date_created date' do
        expect(resource.date_created).to eql date_created
      end
    end

    context 'when created_by date is set' do
      let(:resource) { persist(factory) }

      it 'returns created_by date' do
        expect(resource.date_created).not_to be_nil
      end
    end
  end

  describe '#date_updated' do
    let(:resource) { persist(factory) }

    it 'returns updated_at' do
      expect(resource.date_updated).to eql resource.updated_at
    end
  end
end
