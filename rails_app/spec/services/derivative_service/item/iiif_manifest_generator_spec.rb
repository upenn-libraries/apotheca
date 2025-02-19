# frozen_string_literal: true

describe DerivativeService::Item::IIIFManifestGenerator do
  describe '.new' do
    context 'when parameters do not include an Item' do
      it 'returns an error' do
        expect { described_class.new(nil) }.to raise_error('IIIF manifest can only be generated for ItemResource')
      end
    end
  end

  describe '#v2_manifest' do
    subject(:iiif_service) { described_class.new(item) }

    context 'when item contains image assets' do
      subject(:json) { JSON.parse(iiif_service.v2_manifest.read) }

      let(:item) do
        persist(
          :item_resource, :with_full_assets_all_arranged,
          descriptive_metadata: {
            title: [{ value: 'New Item' }],
            name: [{ value: 'Random, Person', role: [{ value: 'Illustrator' }, { value: 'Creator' }] }],
            rights: [{ value: 'In Copyright', uri: 'http://rightsstatements.org/vocab/InC/1.0/' }],
            rights_note: [{ value: 'Contact copyright owner' }]
          }
        )
      end

      it 'includes top level attributes' do
        expect(json).to include(
          '@id' => 'https://colenda.library.upenn.edu/items/ark:/99999/fk4random/manifest',
          'label' => 'New Item',
          'viewingHint' => 'individuals',
          'viewingDirection' => 'left-to-right',
          'attribution' => 'Provided by the University of Pennsylvania Libraries.'
        )
      end

      it 'includes manifest metadata' do
        expect(json['metadata']).to contain_exactly(
          { 'label' => 'Available Online', 'value' => [starting_with('https://colenda.library.upenn.edu/catalog/')] },
          { 'label' => 'Title', 'value' => ['New Item'] },
          { 'label' => 'Name', 'value' => ['Random, Person (Illustrator, Creator)'] },
          { 'label' => 'Rights', 'value' => ['http://rightsstatements.org/vocab/InC/1.0/'] },
          { 'label' => 'Rights Note', 'value' => ['Contact copyright owner'] }
        )
      end

      it 'includes thumbnail' do
        expect(json['thumbnail']).to a_hash_including(
          '@id' => starting_with('https://serverless_iiif.library.upenn.edu/iiif/2')
                     .and(ending_with('/full/!200,200/0/default.jpg')),
          'service' => {
            '@context' => 'http://iiif.io/api/image/2/context.json',
            '@id' => starting_with('https://serverless_iiif.library.upenn.edu/iiif/2'),
            'profile' => 'http://iiif.io/api/image/2/level2.json'
          }
        )
      end

      it 'includes ranges' do
        expect(json['structures'][0]).to include(
          'label' => 'Front',
          'ranges' => containing_exactly(
            a_hash_including(
              '@id' => 'https://colenda.library.upenn.edu/items/ark:/99999/fk4random/range/r1-1',
              'label' => 'Front of Card',
              'canvases' => containing_exactly('https://colenda.library.upenn.edu/items/ark:/99999/fk4random/canvas/p1')
            )
          )
        )
      end

      it 'includes sequence' do
        sequence = json['sequences'][0]
        expect(sequence).to include('label' => 'Current order')
        expect(sequence['canvases'].count).to be 2
      end

      it 'includes rendering in sequence' do
        expect(json['sequences'][0]['rendering']).to include(
          '@id' => starting_with('https://colenda.library.upenn.edu/items'),
          'label' => 'Download PDF',
          'format' => 'application/pdf'
        )
      end

      it 'includes canvases in sequence' do
        canvases = json['sequences'][0]['canvases']
        expect(canvases[0]).to include(
          '@id' => 'https://colenda.library.upenn.edu/items/ark:/99999/fk4random/canvas/p1',
          'label' => 'Front',
          'height' => 238,
          'width' => 400,
          'images' => contain_exactly(
            a_hash_including(
              'resource' => a_hash_including(
                '@id' => starting_with('https://serverless_iiif.library.upenn.edu/iiif/2'),
                'width' => 400,
                'height' => 238
              )
            )
          ),
          'rendering' => containing_exactly(
            a_hash_including(
              'label' => 'Original File - 291 KB',
              'format' => 'image/tiff'
            )
          )
        )
        expect(canvases[1]).to include(
          'label' => 'p. 2',
          'height' => 238,
          'width' => 400,
          'images' => contain_exactly(
            a_hash_including(
              'resource' => a_hash_including(
                '@id' => starting_with('https://serverless_iiif.library.upenn.edu/iiif/2'),
                'width' => 400,
                'height' => 238
              )
            )
          ),
          'rendering' => containing_exactly(
            a_hash_including(
              'label' => 'Original File - 291 KB',
              'format' => 'image/tiff'
            )
          )
        )
      end
    end

    context 'when item contains image assets that are missing derivatives' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'raises an error' do
        expect { iiif_service.v2_manifest }.to raise_error(
          DerivativeService::Item::IIIFManifestGenerator::MissingDerivative
        )
      end
    end

    context 'when item only contains non-image assets' do
      let(:asset) { persist(:asset_resource, technical_metadata: { mime_type: 'audio/wav' }) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'returns nil' do
        expect(iiif_service.v2_manifest).to be_nil
      end
    end
  end
end
