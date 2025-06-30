# frozen_string_literal: true

describe DerivativeService::Item::Derivatives do
  let(:item) { ItemChangeSet.new(ItemResource.new) }

  describe '#new' do
    context 'when item is not an ItemResource' do
      let(:item) { AssetChangeSet.new(AssetResource.new) }

      it 'raises an error' do
        expect { described_class.new(item) }.to raise_error(ArgumentError, 'Item provided must be a ItemChangeSet')
      end
    end
  end

  describe '#iiif_manifest' do
    it 'calls the correct generator' do
      iiif_generator = instance_spy(DerivativeService::Item::V2IIIFManifestGenerator)
      allow(DerivativeService::Item::V2IIIFManifestGenerator).to receive(:new).with(item.resource)
                                                                              .and_return(iiif_generator)
      described_class.new(item).iiif_manifest
      expect(iiif_generator).to have_received(:manifest)
    end
  end

  describe '#pdf' do
    it 'calls the correct generator' do
      pdf_generator = instance_spy(DerivativeService::Item::PDFGenerator)
      allow(DerivativeService::Item::PDFGenerator).to receive(:new).with(item.resource)
                                                                   .and_return(pdf_generator)
      described_class.new(item).pdf
      expect(pdf_generator).to have_received(:pdf)
    end
  end
end
