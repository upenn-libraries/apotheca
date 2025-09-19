# frozen_string_literal: true

describe PublishingService::Endpoint do
  let(:config) { Settings.publish.digital_collections }
  let(:endpoint) { described_class.new(config) }
  let(:item_id) { SecureRandom.uuid }

  describe '.new' do
    context 'when missing configuration value' do
      before { config.item_path = '' }
      after { config.item_path = 'items' }

      it 'raises error' do
        expect { endpoint }.to raise_error 'Missing publishing configuration for item_path'
      end
    end
  end

  describe '#item_url' do
    it 'returns expected url' do
      expect(
        endpoint.item_url(item_id)
      ).to eql("https://digitalcollections.library.upenn.edu/items/#{item_id}")
    end
  end
end
