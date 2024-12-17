# frozen_string_literal: true

require 'open3'

describe DerivativeService::Asset::TesseractWrapper do
  let(:language) { [] }
  let(:input_path) { Rails.root.join('spec/fixtures/files/trade_card/original/front.tif') }
  let(:output_path) { Pathname.new("#{Dir.tmpdir}/tesseract-test") }
  let(:tesseract) { described_class.new(input_path: input_path, output_path: output_path, language: language) }

  after { FileUtils.rm(Dir.glob("#{Dir.tmpdir}/tesseract-test*")) }

  describe '#ocr' do
    context 'with a blank language' do
      it 'returns nil' do
        expect(tesseract.ocr).to be_nil
      end

      it 'does not execute the tesseract command' do
        allow(tesseract).to receive(:execute_tesseract)
        tesseract.ocr
        expect(tesseract).not_to have_received(:execute_tesseract)
      end
    end

    context 'with an invalid language' do
      let(:language) { ['invalid'] }

      it 'returns nil' do
        expect(tesseract.ocr).to be_nil
      end

      it 'does not execute the tesseract command' do
        allow(tesseract).to receive(:execute_tesseract)
        tesseract.ocr
        expect(tesseract).not_to have_received(:execute_tesseract)
      end
    end

    context 'with a valid language' do
      let(:language) { ['eng'] }

      it 'outputs files at the expected path' do
        tesseract.ocr
        files = Dir.glob("#{output_path}.*")
        expect(files).to contain_exactly("#{output_path}.#{described_class::TEXT_FORMAT}",
                                         "#{output_path}.#{described_class::PDF_FORMAT}",
                                         "#{output_path}.#{described_class::HOCR_FORMAT}")
      end
    end
  end

  describe '#text_extracted?' do
    context 'when text is extracted' do
      let(:language) { ['eng'] }

      it 'returns true' do
        tesseract.ocr
        expect(tesseract.text_extracted?).to be true
      end
    end

    context 'when no text is extracted' do
      let(:input_path) { Rails.root.join('spec/fixtures/files/trade_card/original/back.tif') }

      it 'returns false' do
        tesseract.ocr
        expect(tesseract.text_extracted?).to be false
      end
    end
  end
end
