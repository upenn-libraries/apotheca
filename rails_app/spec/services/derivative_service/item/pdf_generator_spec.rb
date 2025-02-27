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
    let(:item) { persist(:item_resource, :with_faker_metadata, :with_full_assets_all_arranged) }
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
        expect(pdf.pages.count).to eql item.arranged_assets.count + 1
      end

      it 'contains cover page with title' do
        expect(pdf.pages.first.contents).to match(/#{item.descriptive_metadata.title.first.value}/)
      end
    end
  end

  describe '#pdfable?' do
    let(:generator) { described_class.new(item) }

    context 'when item contains arranged image assets' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

      it 'returns true' do
        expect(generator.pdfable?).to be true
      end
    end

    context 'when item does not contain any arranged assets' do
      let(:item) { persist(:item_resource) }

      it 'returns false' do
        expect(generator.pdfable?).to be false
      end
    end

    context 'when item contains a non-image arranged asset' do
      let(:item) do
        persist(:item_resource, :with_full_assets_all_arranged, asset1: persist(:asset_resource, :with_pdf_file))
      end

      it 'returns false' do
        expect(generator.pdfable?).to be false
      end
    end

    context 'when item contains more than 2000 arranged assets' do
      let(:item) { persist(:item_resource, structural_metadata: { arranged_assets_ids: (1...2002).to_a }) }

      it 'returns false' do
        expect(generator.pdfable?).to be false
      end
    end
  end
end
