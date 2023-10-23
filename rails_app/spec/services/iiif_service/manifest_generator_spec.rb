# frozen_string_literal: true

describe IIIFService::ManifestGenerator do
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
      subject(:json) { JSON.parse(iiif_service.v2_manifest) }

      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }
      let(:expected_manifest) { JSON.parse(file_fixture('iiif_manifest/base_item.json').read) }

      it 'includes top level attributes' do
        expect(json).to include(
          '@id' => 'https://colenda.library.upenn.edu/catalog/ark:/99999/fk4random/manifest',
          'label' => 'New Item',
          'viewingHint' => 'individuals',
          'viewingDirection' => 'left-to-right',
          'attribution' => 'Provided by the University of Pennsylvania Libraries.'
        )
      end

      it 'includes ranges' do
        expect(json['structures'][0]).to include(
          'label' => 'Front',
          'ranges' => containing_exactly(
            a_hash_including(
              '@id' => 'https://colenda.library.upenn.edu/catalog/ark:/99999/fk4random/range/r1-1',
              'label' => 'Front of Card',
              'canvases' => containing_exactly('https://colenda.library.upenn.edu/catalog/ark:/99999/fk4random/canvas/p1')
            )
          )
        )
      end

      it 'includes sequence' do
        sequence = json['sequences'][0]
        expect(sequence).to include('label' => 'Current order')
        expect(sequence['canvases'].count).to be 2
      end

      it 'includes canvases in sequence' do
        canvases = json['sequences'][0]['canvases']
        expect(canvases[0]).to include(
          '@id' => 'https://colenda.library.upenn.edu/catalog/ark:/99999/fk4random/canvas/p1',
          "label" => 'Front',
          'height' => 238,
          'width' => 400,
          'images' => contain_exactly(
            a_hash_including(
              'resource' => a_hash_including(
                "@id" => starting_with('https://serverless_iiif.libary.upenn.edu/'),
                'width' => 400,
                'height' => 238
              )
            )
          ),
         'rendering' => containing_exactly(
           a_hash_including(
             'label' => 'Original File - 285 KB',
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
                "@id" => starting_with('https://serverless_iiif.libary.upenn.edu/'),
                'width' => 400,
                'height' => 238
              )
            )
          ),
          'rendering' => containing_exactly(
            a_hash_including(
              'label' => 'Original File - 285 KB',
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
          IIIFService::ManifestGenerator::MissingDerivative
        )
      end
    end

    context 'when item only contains non-image assets' do
      let(:asset) { persist(:asset_resource, technical_metadata: { mime_type: 'audio/wav' }) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'returns nil' do
        expect(iiif_service.v2_manifest).to be nil
      end
    end
  end
end