# frozen_string_literal: true

describe RefreshIlsMetadata do
  describe '#call' do
    let(:transaction) { described_class.new }

    shared_context 'build item with bibnumber' do
      let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
      let(:item) { persist(:item_resource, :with_bibnumber) }

      before do
        stub_request(:get, 'https://marmite.library.upenn.edu:9292/api/v2/records/sample-bib/marc21?update=always')
          .to_return(status: 200, body: marc_xml, headers: {})
        item # build item after Marmite request has been stubbed
      end
    end

    context 'when bibnumber present' do
      include_context 'build item with bibnumber'

      let(:result) { transaction.call(id: item.id.to_s) }

      it 'succeeds' do
        expect(result.success?).to be true
      end

      it 're-persists item to solr index' do
        expect(result.success[:persisted_to_solr_index]).to be true
      end
    end

    context 'when persisting a resource raises an error' do
      include_context 'build item with bibnumber'

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
