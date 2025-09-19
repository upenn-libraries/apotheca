# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::ManifestBuilder do
  let(:item) do
    persist(:item_resource, :with_full_assets_all_arranged)
  end

  describe '#build' do
    let(:manifest) { described_class.new(item).build }

    it 'builds a manifest' do
      expect(manifest).to be_a IIIF::V3::Presentation::Manifest
    end

    it 'assigns top-level attributes' do
      expect(manifest).to have_attributes(
        'id' => ending_with('manifest'),
        'label' => { 'none' => ['New Item'] },
        'viewing_direction' => 'left-to-right',
        'metadata' => all(be_a(Hash)),
        'thumbnail' => all(be_a(Hash)),
        'type' => 'Manifest',
        'rendering' => all(be_a(Hash))
      )
    end

    it 'assigns metadata' do
      expect(manifest.metadata.first).to include(
        'label' => { 'none' => ['Available Online'] },
        'value' => { 'none' => [include('digitalcollections')] }
      )
      expect(manifest.metadata.second).to include(
        'label' => { 'none' => ['Title'] },
        'value' => { 'none' => ['New Item'] }
      )
    end

    it 'assigns thumbnail' do
      expect(manifest.thumbnail).to all(be_a(Hash))
    end

    it 'assigns rendering' do
      expect(manifest.rendering.first).to include(
        'id' => ending_with('pdf'),
        'label' => { 'en' => ['Download PDF'] },
        'format' => 'application/pdf',
        'type' => 'Text'
      )
    end

    it 'assigns items' do
      expect(manifest.items).to all(be_a(IIIF::V3::Presentation::Canvas))
    end
  end
end
