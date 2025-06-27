# frozen_string_literal: true

describe DerivativeService::Item::V3IIIFManifestGenerator do
  describe '.new' do
    context 'when parameters do not include an Item' do
      it 'returns an error' do
        expect { described_class.new(nil) }.to raise_error('IIIF manifest can only be generated for ItemResource')
      end
    end
  end

  describe '#manifest' do
    subject(:iiif_service) { described_class.new(item) }

    context 'when item contains image assets' do
      subject(:json) { JSON.parse(iiif_service.manifest.read) }

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
          'id' => ending_with('manifest'),
          'label' => { 'none' => ['New Item'] },
          'behavior' => ['individuals'],
          'viewingDirection' => 'left-to-right',
          'requiredStatement' => {
            'label' => { 'none' => ['Attribution'] },
            'value' => { 'none' => ['Provided by the University of Pennsylvania Libraries.'] }
          }
        )
      end

      it 'includes manifest metadata' do
        expect(json['metadata']).to contain_exactly(
          { 'label' => { 'none' => ['Available Online'] },
            'value' => { 'none' => [starting_with('https://colenda.library.upenn.edu/catalog/')] } },
          { 'label' => { 'none' => ['Title'] }, 'value' => { 'none' => ['New Item'] } },
          { 'label' => { 'none' => ['Name'] }, 'value' => { 'none' => ['Random, Person (Illustrator, Creator)'] } },
          { 'label' => { 'none' => ['Rights'] },
            'value' => { 'none' => ['http://rightsstatements.org/vocab/InC/1.0/'] } },
          { 'label' => { 'none' => ['Rights Note'] }, 'value' => { 'none' => ['Contact copyright owner'] } }
        )
      end

      it 'includes item level thumbnail' do
        expect(json['thumbnail'].first).to include(
          'id' => starting_with("#{Settings.image_server.url}/iiif/3")
                     .and(ending_with('/full/!200,200/0/default.jpg')),
          'type' => 'Image',
          'format' => 'image/jpeg'
        )
      end

      it 'includes structures' do
        expect(json['structures'].first).to include(
          'id' => ending_with('toc/1'),
          'label' => { 'none' => ['Front of Card, Front'] },
          'items' => containing_exactly(
            a_hash_including(
              'id' => ending_with('toc-canvas/1'),
              'label' => { 'none' => ['Front'] }
            )
          )
        )
      end

      it 'includes items' do
        item = json['items'][0]
        expect(item).to include(
          'type' => 'Canvas',
          'id' => ending_with('canvas'),
          'label' => { 'none' => ['Front'] }
        )
      end

      it 'includes rendering for pdf' do
        expect(json['rendering'][0]).to include(
          'id' => ending_with('pdf'),
          'label' => { 'en' => ['Download PDF'] },
          'type' => 'Text',
          'format' => 'application/pdf'
        )
      end

      it 'includes canvases in items' do
        canvases = json['items']
        expect(canvases[0]).to include(
          'id' => ending_with('canvas'),
          'label' => { 'none' => ['Front'] },
          'height' => 238,
          'width' => 400,
          'items' => contain_exactly(
            a_hash_including(
              'id' => ending_with('annotation-page/1'),
              'type' => 'AnnotationPage',
              'items' => contain_exactly(
                a_hash_including(
                  'id' => ending_with('annotation/1'),
                  'type' => 'Annotation',
                  'motivation' => 'painting',
                  'body' => a_hash_including(
                    'id' => starting_with("#{Settings.image_server.url}/iiif/3"),
                    'height' => 238,
                    'width' => 400
                  )
                )
              )
            )
          ),
          'rendering' => containing_exactly(
            a_hash_including(
              'id' => ending_with('preservation'),
              'label' => { 'en' => ['Original File - 291 KB'] },
              'type' => 'Image',
              'format' => 'image/tiff'
            )
          )
        )
      end
    end

    context 'when item contains image assets that are missing derivatives' do
      let(:asset) { persist(:asset_resource, :with_image_file) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'raises an error' do
        expect { iiif_service.manifest }.to raise_error(
          DerivativeService::Item::V3IIIFManifestGenerator::MissingDerivative
        )
      end
    end

    context 'when item only contains non-image assets' do
      let(:asset) { persist(:asset_resource, technical_metadata: { mime_type: 'audio/wav' }) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'returns nil' do
        expect(iiif_service.manifest).to be_nil
      end
    end
  end
end
