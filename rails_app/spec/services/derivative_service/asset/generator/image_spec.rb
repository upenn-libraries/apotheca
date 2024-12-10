# frozen_string_literal: true

describe DerivativeService::Asset::Generator::Image do
  let(:file) do
    DerivativeService::Asset::SourceFile.new(
      Valkyrie::StorageAdapter::StreamFile.new(id: 1,
                                               io: File.open(file_fixture('files/trade_card/original/front.tif')))
    )
  end

  let(:generator) { described_class.new(file) }

  let(:ocr_types) { described_class::OCR::TYPE_MAP.keys }

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

  describe '#access' do
    subject(:derivative_file) { generator.access }

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

      it 'sets expected iiif_image value of true' do
        expect(derivative_file.iiif_image).to be false
      end

      it 'adds file' do
        expect(derivative_file.size).not_to be 0
      end
    end

    context 'when OCR text has not been extracted from the asset' do
      let(:file) do
        DerivativeService::Asset::SourceFile.new(
          Valkyrie::StorageAdapter::StreamFile.new(id: 1,
                                                   io: File.open(file_fixture('files/trade_card/original/back.tif')))
        )
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

      it 'sets expected iiif_image value of true' do
        expect(derivative_file.iiif_image).to be false
      end

      it 'adds file' do
        expect(derivative_file.size).not_to be 0
      end
    end

    context 'when OCR text has not been extracted from the asset' do
      let(:file) do
        DerivativeService::Asset::SourceFile.new(
          Valkyrie::StorageAdapter::StreamFile.new(id: 1,
                                                   io: File.open(file_fixture('files/trade_card/original/back.tif')))
        )
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#hocr' do
    subject(:derivative_file) { generator.hocr }

    context 'when ocr has been extracted from the imaged' do
      after { ocr_types.each { |type| generator.send(type).cleanup! } }

      it 'returns DerivativeFile' do
        expect(derivative_file).to be_a DerivativeService::DerivativeFile
      end

      it 'sets expected mime_type' do
        expect(derivative_file.mime_type).to eql 'text/html'
      end

      it 'sets expected iiif_image value of true' do
        expect(derivative_file.iiif_image).to be false
      end

      it 'adds file' do
        expect(derivative_file.size).not_to be 0
      end
    end

    context 'when OCR text has not been extracted from the asset' do
      let(:file) do
        DerivativeService::Asset::SourceFile.new(
          Valkyrie::StorageAdapter::StreamFile.new(id: 1,
                                                   io: File.open(file_fixture('files/trade_card/original/back.tif')))
        )
      end

      it { is_expected.to be_nil }
    end
  end
end
