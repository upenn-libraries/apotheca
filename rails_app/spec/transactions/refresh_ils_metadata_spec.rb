# frozen_string_literal: true

describe RefreshIlsMetadata do
  describe '#call' do
    include_context 'with successful Alma request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    end

    let(:transaction) { described_class.new }
    let(:result) { transaction.call(id: item.id.to_s, updated_by: 'initiator@example.com') }
    let(:updated_item) { result.value![:resource] }

    context 'when bibnumber present' do
      let(:item) { persist(:item_resource, :with_bibnumber) }

      include_examples 'creates a resource event', :refresh_ils_metadata, 'initiator@example.com', false do
        let(:resource) { updated_item }
      end

      it 'succeeds' do
        expect(result.success?).to be true
      end
    end

    context 'when persisting a resource raises an error' do
      let(:item) { persist(:item_resource, :with_bibnumber) }

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

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'includes error' do
        expect(result.failure[:error]).to be :no_bib_number
      end
    end

    context 'when the item has already been published' do
      let(:item) { persist(:item_resource, :with_bibnumber, :published) }

      it 'enqueues a PublishItemJob' do
        allow(PublishItemJob).to receive(:perform_async)
        result
        expect(PublishItemJob).to have_received :perform_async
      end
    end

    context 'when the item has not been published' do
      let(:item) { persist(:item_resource, :with_bibnumber) }

      it 'does enqueue a PublishItemJob' do
        allow(PublishItemJob).to receive(:perform_async)
        result
        expect(PublishItemJob).not_to have_received :perform_async
      end
    end
  end
end
