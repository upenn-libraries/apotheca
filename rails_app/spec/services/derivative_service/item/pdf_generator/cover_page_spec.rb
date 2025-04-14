# frozen_string_literal: true

describe DerivativeService::Item::PDFGenerator::CoverPage do
  let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }
  let(:item) do
    persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id], thumbnail_asset_id: asset.id,
                                                  human_readable_name: 'Line Breaks and Other Mishaps')
  end
  let(:cover_page) { described_class.new(item) }
  let(:document) { HexaPDF::Document.new }

  describe '#add_to' do
    before { cover_page.add_to(document) }

    it 'adds a cover page' do
      expect(document.pages.count).to be 1
    end

    it 'adds expected metadata values to cover page' do
      expect(document.pages.first).to have_pdf_text(item.descriptive_metadata.title.first.value)
    end

    it 'adds Colenda link to cover page' do
      url = PublishingService::Endpoint.colenda.public_item_url(item.unique_identifier)
      expect(document.pages.first).to have_pdf_text(url)
    end
  end
end
