# frozen_string_literal: true

describe PublishingService::Endpoint do
  let(:config) { Settings.publish.colenda }
  let(:endpoint) { described_class.new(config) }
  let(:item_id) { 'ark:/1234/5678' }
  let(:asset_id) { '8621662d-ef44-4888-99a8-0f70e340c3b8' }

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
      ).to eql("https://colenda.library.upenn.edu/items/#{item_id}")
    end
  end

  describe '#public_item_url' do
    it 'returns expected url' do
      expect(
        endpoint.public_item_url(item_id)
      ).to eql('https://colenda.library.upenn.edu/catalog/1234-5678')
    end
  end

  describe '#pdf_url' do
    it 'returns expected url' do
      expect(
        endpoint.pdf_url(item_id)
      ).to eql("https://colenda.library.upenn.edu/items/#{item_id}/pdf")
    end
  end

  describe '#manifest_url' do
    it 'returns expected url' do
      expect(
        endpoint.manifest_url(item_id)
      ).to eql("https://colenda.library.upenn.edu/items/#{item_id}/manifest")
    end
  end

  describe '#original_url' do
    it 'returns expected url' do
      expect(
        endpoint.original_url(item_id, asset_id)
      ).to eql("https://colenda.library.upenn.edu/items/#{item_id}/assets/#{asset_id}/original")
    end
  end
end
