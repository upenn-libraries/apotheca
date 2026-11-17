# frozen_string_literal: true

describe Item::Steps::SendUnpublishRequest do
  let(:result) { described_class.new.call(item, endpoint) }
  let(:item) { persist(:item_resource) }
  let(:endpoint) { PublishingEndpoint.digital_collections }

  context 'with successful unpublish request' do
    include_context 'with successful unpublish request'

    it 'is successful' do
      expect(result.success?).to be true
    end

    it 'returns the item wrapped in a Success monad' do
      expect(result.value!).to be item
    end
  end

  context 'with unsuccessful unpublish request' do
    include_context 'with unsuccessful unpublish request'

    it 'fails' do
      expect(result.failure?).to be true
      expect(result.failure[:error]).to be :error_unpublishing_item
    end

    it 'includes error message in json response' do
      expect(result.failure[:message]).to include 'Crazy Solr error'
    end
  end

  context 'with an error unrelated to the request' do
    let(:endpoint) { nil }

    it 'fails' do
      expect(result.failure?).to be true
      expect(result.failure[:error]).to be :error_unpublishing_item
    end

    it 'includes the exception' do
      expect(result.failure[:exception]).to be_a NoMethodError
      expect(result.failure[:exception].message).to eq "undefined method 'host' for nil"
    end
  end
end
