# frozen_string_literal: true

describe DerivativeService::Asset::Generator::Image::OCR do
  let(:file) do
    DerivativeService::Asset::SourceFile.new(
      Valkyrie::StorageAdapter::StreamFile.new(id: 1,
                                               io: File.open(file_fixture('files/trade_card/original/front.tif')))
    )
  end
  let(:asset) { AssetChangeSet.new(AssetResource.new, ocr_language: ['eng']) }
  let(:ocr) { described_class.new(file: file, asset: asset) }

  describe '#generate' do
    let(:derivative_files) { ocr.generate }

    context 'when ocr text is extracted from asset' do
      after { derivative_files.each { |_k, file| file.cleanup! } }

      it 'returns a hash containing DerivativeService::DerivativeFiles' do
        expect(derivative_files).to include({ textonly_pdf: be_a(DerivativeService::DerivativeFile),
                                              text: be_a(DerivativeService::DerivativeFile),
                                              hocr: be_a(DerivativeService::DerivativeFile) })
      end

      it 'returns pdf derivative' do
        expect(derivative_files[:textonly_pdf].path).to end_with('.pdf')
      end

      it 'returns text derivative' do
        expect(derivative_files[:text].path).to end_with('.txt')
      end

      it 'returns hocr derivative' do
        expect(derivative_files[:hocr].path).to end_with('.hocr')
      end
    end

    context 'when no ocr text is extracted from the asset' do
      let(:file) do
        DerivativeService::Asset::SourceFile.new(
          Valkyrie::StorageAdapter::StreamFile.new(id: 1,
                                                   io: File.open(file_fixture('files/trade_card/original/back.tif')))
        )
      end

      it 'returns a hash containing nil values' do
        expect(derivative_files).to eq({ textonly_pdf: nil, text: nil, hocr: nil })
      end

      it 'cleans up the generated files' do
        expect(Dir.new(Dir.tmpdir).entries.none? { |entry| entry.start_with?('ocr-derivative-file-') }).to be true
      end
    end
  end
end
