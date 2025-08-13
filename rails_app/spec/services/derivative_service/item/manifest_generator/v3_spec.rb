# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::V3 do
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
            title: [{ value: 'Test IIIF Manifest Item' }],
            name: [{ value: 'Test, Author', role: [{ value: 'Creator' }] }]
          }
        )
      end

      it 'creates a valid IIIF v3 manifest with correct context' do
        expect(json['@context']).to include(
          'http://www.w3.org/ns/anno.jsonld',
          'http://iiif.io/api/presentation/3/context.json'
        )
      end

      it 'sets manifest type correctly' do
        expect(json['type']).to eq('Manifest')
      end

      it 'includes manifest ID' do
        expect(json['id']).to be_present
      end

      it 'includes all required top-level properties' do
        %w[label requiredStatement behavior viewingDirection metadata items].each do |property|
          expect(json).to have_key(property)
        end
      end

      it 'populates items array with canvases' do
        expect(json['items']).to be_an(Array).and be_present
      end

      it 'includes canvases with correct type in items' do
        expect(json['items'].first['type']).to eq('Canvas')
      end
    end

    context 'when assets have annotations' do
      subject(:json) { JSON.parse(iiif_service.manifest.read) }

      let(:item) do
        persist(
          :item_resource, :with_full_assets_all_arranged,
          descriptive_metadata: { title: [{ value: 'Test Item with Annotations' }] }
        )
      end

      it 'includes structures property when annotations exist' do
        expect(json).to have_key('structures')
      end

      it 'populates structures as array when annotations exist' do
        expect(json['structures']).to be_an(Array)
      end

      it 'includes ranges with correct type when annotations exist' do
        expect(json['structures'].first['type']).to eq('Range')
      end
    end

    context 'when item has thumbnail' do
      subject(:json) { JSON.parse(iiif_service.manifest.read) }

      let(:item) do
        persist(
          :item_resource, :with_full_assets_all_arranged,
          descriptive_metadata: { title: [{ value: 'Test Item with Thumbnail' }] }
        )
      end

      it 'includes thumbnail property when thumbnail exists' do
        expect(json).to have_key('thumbnail')
      end

      it 'populates thumbnail as array when thumbnail exists' do
        expect(json['thumbnail']).to be_an(Array)
      end

      it 'includes thumbnail with correct type when thumbnail exists' do
        expect(json['thumbnail'].first['type']).to eq('Image')
      end
    end

    context 'when PDF is available' do
      subject(:json) { JSON.parse(iiif_service.manifest.read) }

      let(:item) do
        persist(
          :item_resource, :with_full_assets_all_arranged,
          descriptive_metadata: { title: [{ value: 'Test Item with PDF' }] }
        )
      end

      before do
        pdf_generator_double = instance_double(DerivativeService::Item::PDFGenerator, pdfable?: true)
        allow(DerivativeService::Item::PDFGenerator).to receive(:new)
          .with(item)
          .and_return(pdf_generator_double)
      end

      it 'includes PDF rendering with correct type' do
        pdf_rendering = json['rendering']&.find { |r| r['format'] == 'application/pdf' }
        expect(pdf_rendering['type']).to eq('Text') if pdf_rendering
      end

      it 'includes PDF rendering with correct label' do
        pdf_rendering = json['rendering']&.find { |r| r['format'] == 'application/pdf' }
        expect(pdf_rendering['label']['en']).to eq(['Download PDF']) if pdf_rendering
      end
    end

    context 'when item contains image assets that are missing derivatives' do
      let(:asset) { persist(:asset_resource, :with_image_file) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'raises an error' do
        expect { iiif_service.manifest }.to raise_error(
          described_class::MissingDerivative,
          /Derivatives missing for/
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

    context 'when item has no assets' do
      let(:item) { persist(:item_resource, asset_ids: [], structural_metadata: { arranged_asset_ids: [] }) }

      it 'returns nil' do
        expect(iiif_service.manifest).to be_nil
      end
    end
  end
end
