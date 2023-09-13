# frozen_string_literal: true

shared_examples_for 'ModificationDetails' do |factory|
  describe '#date_created' do
    context 'when first_created_at is set' do
      let(:first_created_at) { DateTime.new(2000, 2, 1) }
      let(:resource) { persist(factory, first_created_at: first_created_at) }

      it 'returns first_created_at date' do
        expect(resource.date_created).to eql first_created_at
      end
    end

    context 'when only created_at date is set' do
      let(:resource) { persist(factory) }

      it 'returns created_at date' do
        expect(resource.first_created_at).to be_nil
        expect(resource.date_created).to eql resource.created_at
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
