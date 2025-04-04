# frozen_string_literal: true

describe ItemQueries do
  let(:query) do
    described_class.new(query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service)
  end

  describe '#find_by_unique_identifier' do
    let(:unique_identifier) { 'ark:/99999/fk4vx4' }
    let(:item) { persist(:item_resource, unique_identifier: unique_identifier) }

    before do
      item
      persist(:item_resource)
    end

    context 'when item with unique_identifier exists' do
      it 'returns expected item' do
        expect(query.find_by_unique_identifier(unique_identifier: unique_identifier).id).to eql item.id
      end
    end

    context 'when item with unique_identifier is not found' do
      it 'returns nil' do
        expect(query.find_by_unique_identifier(unique_identifier: 'ark:/random/random')).to be_nil
      end
    end
  end

  describe '#find_by_ocr_type' do
    before { persist(:item_resource) }
    context 'when item with printed ocr_type exists' do
      let(:item) { persist(:item_resource, ocr_type: 'printed') }

      before { item }

      it 'returns expected item' do
        expect(query.find_by_ocr_type(ocr_type: 'printed').first.id).to eql item.id
      end
    end

    context 'when item with ocr_type does not exist' do
      it 'returns empty array' do
        expect(query.find_by_ocr_type(ocr_type: 'printed').count).to be 0
      end
    end
  end
end
