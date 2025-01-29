# frozen_string_literal: true

describe DerivativeService::Item::PDFGenerator::AssetWrapper do
  let(:asset) { persist(:asset_resource, :with_preservation_file, :with_derivatives, :with_metadata) }
  let(:asset_wrapper) { described_class.new(asset) }

  describe '#image_dpi' do
    it 'returns expected value' do
      expect(asset_wrapper.image_dpi).to be 300
    end
  end

  describe '#image' do
    it 'returns derivative file' do
      expect(asset_wrapper.image).to be_a DerivativeService::DerivativeFile
      expect(asset_wrapper.image.length).not_to be 0
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
      let(:asset) { persist(:asset_resource, :with_preservation_file, :with_metadata) }

      it 'returns nil' do
        expect(asset_wrapper.textonly_pdf).to be nil
      end
    end
  end

  describe 'label' do
    it 'returns expected value' do
      expect(asset_wrapper.label).to eql 'Front'
    end
  end

  describe 'annotations' do
    it 'returns expected value' do
      expect(asset_wrapper.annotations).to match_array('Front of Card')
    end
  end
end
