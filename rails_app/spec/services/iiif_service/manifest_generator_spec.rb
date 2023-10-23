# frozen_string_literal: true

describe IIIFService::ManifestGenerator do
  describe '.new' do
    context 'when parameters do not include an Item' do
      it 'returns an error' do
        expect { described_class.new(nil) }.to raise_error('IIIF manifest can only be generated for ItemResource')
      end
    end
  end

  describe '#v2_manifest' do
    subject(:iiif_service) { described_class.new(item) }

    context 'when item contains image assets' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }
      let(:expected_manifest) { JSON.parse(file_fixture('iiif_manifest/base_item.json').read) }

      it 'generates expected iiif manifest' do
        expect(JSON.parse(iiif_service.v2_manifest)).to eq expected_manifest
      end
    end

    context 'when item contains image assets that are missing derivatives' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'raises an error' do
        expect { iiif_service.v2_manifest }.to raise_error(
          IIIFService::ManifestGenerator::MissingDerivative
        )
      end
    end

    context 'when item only contains non-image assets' do
      let(:asset) { persist(:asset_resource, technical_metadata: { mime_type: 'audio/wav' }) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'returns nil' do
        expect(iiif_service.v2_manifest).to be nil
      end
    end
  end
end