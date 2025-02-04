# frozen_string_literal: true

describe DerivativeService::Item::PDFGenerator do
  describe '.new' do
    context 'when parameters do not include an Item' do
      it 'returns an error' do
        expect { described_class.new(nil) }.to raise_error('PDF can only be generated for ItemResource')
      end
    end
  end

  describe '#pdf' do
    let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }
    let(:generator) { described_class.new(item) }

    context 'when pdf can be generated' do
      let(:derivative_file) { generator.pdf }
      let(:pdf) { HexaPDF::Document.open(derivative_file.path) }

      it 'returns DerivativeFile' do
        expect(derivative_file).to be_a DerivativeService::DerivativeFile
      end

      it 'sets expected mime_type' do
        expect(derivative_file.mime_type).to eql 'application/pdf'
      end

      it 'adds file' do
        expect(derivative_file.length).not_to be 0
      end

      it 'contains expected number of pages' do
        expect(pdf.pages.count).to eql item.arranged_assets.count
      end
    end
  end
end
