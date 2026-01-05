# frozen_string_literal: true

describe DerivativeService::Item::PDFGenerator::AssetWrapper do
  let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives, :with_metadata) }
  let(:asset_wrapper) { described_class.new(asset) }

  describe '#image_dpi' do
    it 'returns expected value' do
      expect(asset_wrapper.image_dpi).to be 300
    end
  end

  describe '#image' do
    context 'when iiif_image present' do
      it 'returns derivative file' do
        expect(asset_wrapper.image).to be_a DerivativeService::DerivativeFile
        expect(asset_wrapper.image.length).not_to be 0
      end
    end
  end

  describe '#textonly_pdf' do
    context 'when textonly_pdf present' do
      it 'returns derivative file' do
        expect(asset_wrapper.textonly_pdf).to be_a Valkyrie::StorageAdapter::StreamFile
        expect(asset_wrapper.textonly_pdf.size).not_to be 0
      end
    end

    context 'when textonly_pdf not present' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_metadata) }

      it 'returns nil' do
        expect(asset_wrapper.textonly_pdf).to be_nil
      end
    end
  end

  describe '#label' do
    it 'returns expected value' do
      expect(asset_wrapper.label).to eql 'Front'
    end
  end

  describe '#annotations' do
    it 'returns expected value' do
      expect(asset_wrapper.annotations).to match_array('Front of Card')
    end
  end

  describe '#cleanup' do
    it 'cleans up image file' do
      image = instance_double(DerivativeService::DerivativeFile, cleanup!: nil)
      allow(asset_wrapper).to receive(:image).and_return(image)
      asset_wrapper.cleanup!
      expect(image).to have_received(:cleanup!)
    end

    it 'cleans up textonly_pdf file' do
      textonly_pdf = instance_double(Valkyrie::StorageAdapter::StreamFile, close: nil)
      allow(asset_wrapper).to receive(:textonly_pdf).and_return(textonly_pdf)
      asset_wrapper.cleanup!
      expect(textonly_pdf).to have_received(:close)
    end
  end
end
