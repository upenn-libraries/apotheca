# frozen_string_literal: true

describe RefreshIlsMetadata do
  describe '#call' do
    include_context 'with successful Marmite request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    end

    let(:transaction) { described_class.new }

    context 'when bibnumber present' do
      let(:item) { persist(:item_resource, :with_bibnumber) }
      let(:result) { transaction.call(id: item.id.to_s) }

      it 'succeeds' do
        expect(result.success?).to be true
      end

      it 're-persists item to solr index' do
        expect(result.value!).to be true
      end
    end

    context 'when persisting a resource raises an error' do
      let(:item) { persist(:item_resource, :with_bibnumber) }
      let(:result) { transaction.call(id: item.id.to_s) }

      before do
        allow(transaction).to receive(:persister).and_raise(StandardError)
      end

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns expected failure' do
        expect(result.failure[:error]).to be :error_persisting_to_solr_index
        expect(result.failure[:exception]).to be_a StandardError
      end
    end

    context 'when the item does not have bibnumber' do
      let(:item) { persist(:item_resource) }
      let(:result) { transaction.call(id: item.id.to_s) }

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'includes error' do
        expect(result.failure[:error]).to be :no_bib_number
      end
    end
  end
end
