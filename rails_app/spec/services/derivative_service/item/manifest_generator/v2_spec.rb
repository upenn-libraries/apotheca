# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::V2 do
  describe '.new' do
    context 'when parameters do not include an Item' do
      it 'returns an error' do
        expect { described_class.new(nil) }.to raise_error('IIIF manifest can only be generated for ItemResource')
      end
    end
  end

  describe '#manifest' do
    subject(:derivative_generator) { described_class.new(item) }

    context 'when item contains image assets' do
      let(:item) do
        persist(:item_resource, :with_full_assets_all_arranged)
      end

      it 'returns a derivative file' do
        expect(derivative_generator.manifest).to be_a DerivativeService::DerivativeFile
      end

      it 'creates a IIIF v2 manifest' do
        json = JSON.parse(derivative_generator.manifest.read)
        expect(json['@context']).to eql('http://iiif.io/api/presentation/2/context.json')
      end
    end

    context 'when item only contains non-image assets' do
      let(:asset) { persist(:asset_resource, technical_metadata: { mime_type: 'audio/wav' }) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'returns nil' do
        expect(derivative_generator.manifest).to be_nil
      end
    end
  end
end
