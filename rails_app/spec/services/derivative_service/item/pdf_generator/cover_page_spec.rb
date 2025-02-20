# frozen_string_literal: true

describe DerivativeService::Item::PDFGenerator::CoverPage do
  let(:asset) { persist(:asset_resource, :with_preservation_file, :with_derivatives) }
  let(:item) { persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id], thumbnail_asset_id: asset.id) }
  let(:cover_page) { described_class.new(item) }
  let(:document) { HexaPDF::Document.new }

  describe '#add_to' do
    before { cover_page.add_to(document) }

    it 'adds a cover page' do
      expect(document.pages.count).to be 1
    end

    it 'adds expected metadata values to cover page' do
      expect(document.pages.first.contents).to match(/#{item.descriptive_metadata.title.first.value}/)
      expect(document.pages.first.contents).to match(/#{item.descriptive_metadata.title.first.value}/)
    end

    it 'adds Colenda link to cover page' do
      url = "https://colenda.library.upenn.edu/catalog/#{item.unique_identifier.gsub('ark:/', '').tr('/', '-')}"
      expect(document.pages.first.contents).to match(/#{url}/)
    end
  end
end
