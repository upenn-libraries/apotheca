# frozen_string_literal: true

require 'hexapdf'

describe DerivativeService::Item::PDFGenerator::CoverPage do
  let(:asset) { persist(:asset_resource, :with_preservation_file, thumbnail: true) }
  let(:item) { persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id], thumbnail_asset_id: asset.id) }
  let(:cover_page) { described_class.new(item: item) }

  describe '#page' do
    it 'returns a page' do
      expect(cover_page.page).to be_a HexaPDF::Type::Page
    end

    it 'contains the expected contents' do
      expect(cover_page.page.contents).to match(/#{item.descriptive_metadata.title.first.value}/)
      expect(cover_page.page.contents).to match(/#{item.descriptive_metadata.title.first.value}/)
    end

    it 'contains a link to the item on colenda' do
      url = "#{Settings.iiif.manifest.item_link_base_url}#{item.unique_identifier.gsub('ark:/', '').tr('/', '-')}"
      expect(cover_page.page.contents).to match(/#{url}/)
    end
  end

  describe '#write' do
    it 'writes the pdf at the given path' do
      tmp_file = Tempfile.new
      expect(tmp_file.size).to be_zero
      cover_page.write(path: tmp_file.path)
      expect(tmp_file.size).to be_positive
    end
  end
end
