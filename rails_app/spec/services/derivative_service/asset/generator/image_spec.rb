# frozen_string_literal: true

require_relative 'base'

describe DerivativeService::Asset::Generator::Image do
  let(:resource) { persist(:asset_resource, :with_image_file) }
  let(:generator) { described_class.new(AssetChangeSet.new(resource, ocr_strategy: 'printed', ocr_language: ['eng'])) }
  let(:ocr_types) { described_class::OCR::TYPE_MAP.keys }

  it_behaves_like 'a DerivativeService::Asset::Generator::Base'

  describe '#thumbnail' do
    subject(:derivative_file) { generator.thumbnail }

    it 'returns DerivativeFile' do
      expect(derivative_file).to be_a DerivativeService::DerivativeFile
    end

    it 'sets expected mime_type' do
      expect(derivative_file.mime_type).to eql 'image/jpeg'
    end

    it 'sets expected iiif_image value of false' do
      expect(derivative_file.iiif_image).to be false
    end

    it 'adds file' do
      expect(derivative_file.size).not_to be 0
    end
  end

  describe '#iiif_image' do
    subject(:derivative_file) { generator.iiif_image }

    it 'returns DerivativeFile' do
      expect(derivative_file).to be_a DerivativeService::DerivativeFile
    end

    it 'sets expected mime_type' do
      expect(derivative_file.mime_type).to eql 'image/tiff'
    end

    it 'sets expected iiif_image value of true' do
      expect(derivative_file.iiif_image).to be true
    end

    it 'adds file' do
      expect(derivative_file.size).not_to be 0
    end
  end

  describe '#textonly_pdf' do
    subject(:derivative_file) { generator.textonly_pdf }

    context 'when ocr has been extracted from the asset' do
      after { ocr_types.each { |type| generator.send(type).cleanup! } }

      it 'returns DerivativeFile' do
        expect(derivative_file).to be_a DerivativeService::DerivativeFile
      end

      it 'sets expected mime_type' do
        expect(derivative_file.mime_type).to eql 'application/pdf'
      end

      it 'sets expected iiif_image value' do
        expect(derivative_file.iiif_image).to be false
      end

      it 'adds file' do
        expect(derivative_file.size).not_to be 0
      end
    end

    context 'when OCR text has not been extracted from the asset' do
      let(:resource) do
        persist(:asset_resource, :with_image_file, preservation_file: 'trade_card/original/back.tif')
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#text' do
    subject(:derivative_file) { generator.text }

    context 'when ocr has been extracted from the image' do
      after { ocr_types.each { |type| generator.send(type).cleanup! } }

      it 'returns DerivativeFile' do
        expect(derivative_file).to be_a DerivativeService::DerivativeFile
      end

      it 'sets expected mime_type' do
        expect(derivative_file.mime_type).to eql 'text/plain'
      end

      it 'sets expected iiif_image value' do
        expect(derivative_file.iiif_image).to be false
      end

      it 'adds file' do
        expect(derivative_file.size).not_to be 0
      end
    end

    context 'when OCR text has not been extracted from the asset' do
      let(:resource) do
        persist(:asset_resource, :with_image_file, preservation_file: 'trade_card/original/back.tif')
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#hocr' do
    subject(:derivative_file) { generator.hocr }

    context 'when ocr has been extracted from the image' do
      after { ocr_types.each { |type| generator.send(type).cleanup! } }

      it 'returns DerivativeFile' do
        expect(derivative_file).to be_a DerivativeService::DerivativeFile
      end

      it 'sets expected mime_type' do
        expect(derivative_file.mime_type).to eql 'text/html'
      end

      it 'sets expected iiif_image value' do
        expect(derivative_file.iiif_image).to be false
      end

      it 'adds file' do
        expect(derivative_file.size).not_to be 0
      end
    end

    context 'when OCR text has not been extracted from the asset' do
      let(:resource) do
        persist(:asset_resource, :with_image_file, preservation_file: 'trade_card/original/back.tif')
      end

      it { is_expected.to be_nil }
    end
  end
end
