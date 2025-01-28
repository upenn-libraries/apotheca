# frozen_string_literal: true

require 'hexapdf'

describe DerivativeService::Item::PDFGenerator::CoverPage do
  let(:asset) { persist(:asset_resource, :with_preservation_file, thumbnail: true) }
  let(:item) { persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id], thumbnail_asset_id: asset.id) }
  let(:cover_page) { described_class.new(item: item) }

  describe '#generate' do
    it 'returns a page' do
      expect(cover_page.generate).to be_a HexaPDF::Type::Page
    end
  end
end
