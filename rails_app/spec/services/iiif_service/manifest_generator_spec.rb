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

    let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }
    let(:expected_manifest) { JSON.parse(file_fixture('iiif_manifest/base_item.json').read) }

    it 'generates expected iiif manifest' do
      expect(JSON.parse(iiif_service.v2_manifest)).to eq expected_manifest
    end
  end
end