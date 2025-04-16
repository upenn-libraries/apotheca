# frozen_string_literal: true

describe DerivativeService::Item::PDFGenerator::Cover do
  let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }
  let(:item) do
    persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id], thumbnail_asset_id: asset.id,
                                                  description_count: 50,
                                                  human_readable_name: 'Line Breaks and Other Mishaps')
  end
  let(:cover) { described_class.new(item) }
  let(:target) { HexaPDF::Document.new }

  describe '#add_pages_to' do
    before { cover.add_pages_to(target) }

    it 'adds a cover pages' do
      expect(target.pages.count).to be cover.document.pages.count
    end

    it 'adds title to first page' do
      expect(target.pages.first).to have_pdf_text(item.descriptive_metadata.title.first.value)
    end

    it 'adds Colenda link to first page' do
      url = PublishingService::Endpoint.colenda.public_item_url(item.unique_identifier)
      expect(target.pages.first).to have_pdf_text(url)
    end

    it 'adds collection to last page' do
      expect(target.pages.to_a.last).to have_pdf_text(item.descriptive_metadata.collection.first.value)
    end
  end
end
