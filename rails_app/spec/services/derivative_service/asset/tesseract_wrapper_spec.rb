# frozen_string_literal: true

require 'open3'

describe DerivativeService::Asset::TesseractWrapper do
  let(:language_preparer) { described_class::LanguagePreparer.new(languages: language) }
  let(:tesseract) { described_class.new(language_preparer: language_preparer) }
  let(:input_path) { Rails.root.join('spec/fixtures/files/trade_card/original/front.tif') }

  describe '#ocr' do
    context 'when language_preparer argument is blank' do
      let(:language) { [] }

      it 'returns nil' do
        output_file = Tempfile.new
        expect(tesseract.ocr(input_path: input_path, output_path: output_file.path)).to be_nil
        output_file.unlink
      end

      it 'does not execute the tesseract command' do
        output_file = Tempfile.new
        allow(tesseract).to receive(:execute_tesseract)
        tesseract.ocr(input_path: input_path, output_path: output_file.path)
        expect(tesseract).not_to have_received(:execute_tesseract)
        output_file.unlink
      end
    end

    context 'with multiple file formats' do
      let(:language) { ['eng'] }
      let(:format) { %w[txt hocr] }

      it 'outputs files at the expected path' do
        output_path = Pathname.new("#{Dir.tmpdir}/test")
        tesseract.ocr(input_path: input_path, output_path: output_path, format: format)
        expect(format.all? { |format| output_path.sub_ext(".#{format}").exist? }).to be true
        format.each { |format| output_path.sub_ext(".#{format}") }
      end
    end
  end
end
