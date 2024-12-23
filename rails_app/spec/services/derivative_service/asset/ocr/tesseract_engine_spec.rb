# frozen_string_literal: true

require 'open3'

describe DerivativeService::Asset::OCR::TesseractEngine do
  let(:input_path) { Rails.root.join('spec/fixtures/files/trade_card/original/front.tif') }
  let(:output_path) { Pathname.new("#{Dir.tmpdir}/tesseract-test") }
  let(:tesseract) { described_class.new(language: ['eng'], viewing_direction: nil) }

  describe '#ocr' do
    let(:ocr) { tesseract.ocr(input_path: input_path, output_path: output_path) }

    context 'when text is extracted' do
      after { FileUtils.rm(Dir.glob("#{Dir.tmpdir}/tesseract-test*")) }

      it 'returns expected files' do
        expect(ocr.size).to eq 3
        expect(ocr.all? { |f| f.is_a?(File) }).to be true
      end

      it 'creates files at expected path' do
        expect(ocr.map(&:path)).to contain_exactly("#{output_path}.#{described_class::TEXT_FORMAT}",
                                                   "#{output_path}.#{described_class::PDF_FORMAT}",
                                                   "#{output_path}.#{described_class::HOCR_FORMAT}")
      end
    end

    context 'when no text is extracted' do
      let(:input_path) { Rails.root.join('spec/fixtures/files/trade_card/original/back.tif') }

      it 'returns an empty array' do
        expect(ocr).to be_empty
      end

      it 'cleans up blank ocr files' do
        ocr
        files = Dir.glob("#{output_path}.*")
        expect(files).to be_empty
      end
    end
  end

  describe '#ocrable?' do
    context 'with a valid language' do
      it 'returns true' do
        expect(tesseract.ocrable?).to be true
      end
    end

    context 'with an invalid language' do
      let(:tesseract) { described_class.new(language: ['invalid'], viewing_direction: nil) }

      it 'returns false' do
        expect(tesseract.ocrable?).to be false
      end
    end
  end
end
