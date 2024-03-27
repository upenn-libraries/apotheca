# frozen_string_literal: true

describe DerivativeService::Item::Derivatives do
  describe '#new' do
    context 'when item is not an ItemResource' do
      let(:item) { AssetChangeSet.new(AssetResource.new) }

      it 'raises an error' do
        expect { described_class.new(item) }.to raise_error(ArgumentError, 'Item provided must be a ItemChangeSet')
      end
    end
  end

  describe '#iiif_manifest' do
    let(:item) { ItemChangeSet.new(ItemResource.new) }

    it 'calls the correct generator' do
      iiif_generator = instance_spy(DerivativeService::Item::IIIFManifestGenerator)
      allow(DerivativeService::Item::IIIFManifestGenerator).to receive(:new).with(item.resource)
                                                                            .and_return(iiif_generator)
      described_class.new(item).iiif_manifest
      expect(iiif_generator).to have_received(:v2_manifest)
    end
  end
end
