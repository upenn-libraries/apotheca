# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::V2::ManifestBuilder do
  describe '#build' do
    context 'when all image assets contain derivatives' do
      subject(:manifest) { described_class.new(item).build }

      let(:item) do
        persist(:item_resource, :with_full_assets_all_arranged)
      end

      it 'builds a manifest' do
        expect(manifest).to be_a IIIF::Presentation::Manifest
      end

      it 'assigns id' do
        expect(manifest['@id']).to match(%r{/iiif/2/items/.+/manifest$})
      end

      it 'assigns top level attributes' do
        expect(manifest).to have_attributes(
          'label' => 'New Item',
          'viewingHint' => 'individuals',
          'viewingDirection' => 'left-to-right',
          'attribution' => 'Provided by the University of Pennsylvania Libraries.'
        )
      end

      it 'includes metadata' do
        expect(manifest.metadata.length).to be 2
      end

      it 'includes thumbnail' do
        expect(manifest.thumbnail).to a_hash_including(
          '@id': starting_with(Settings.image_server.url.to_s)
                    .and(ending_with('/full/!600,600/0/default.jpg')),
          service: {
            '@context': 'http://iiif.io/api/image/2/context.json',
            '@id': starting_with("#{Settings.image_server.url}/iiif/2"),
            profile: 'http://iiif.io/api/image/2/level2.json'
          }
        )
      end

      it 'includes sequence' do
        sequence = manifest.sequences.first
        expect(sequence).to have_attributes(label: 'Current order')
        expect(sequence['canvases'].count).to be 2
      end

      it 'includes structures (table of contents)' do
        expect(manifest.structures.count).to be 1
      end
    end

    context 'when some image assets that are missing derivatives' do
      let(:asset) { persist(:asset_resource, :with_image_file) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'raises an error' do
        expect {
          described_class.new(item).build
        }.to raise_error(DerivativeService::Item::ManifestGenerator::V2::ManifestBuilder::MissingDerivative)
      end
    end
  end
end
