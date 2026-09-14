# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::V2::CanvasBuilder do
  describe '#build' do
    subject(:canvas) { described_class.new(asset: asset, index: 1).build }

    let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives, :with_metadata) }

    it 'builds canvas' do
      expect(canvas).to be_a IIIF::Presentation::Canvas
    end

    it 'assigns id' do
      expect(canvas['@id']).to match(%r{/iiif/2/assets/.+/canvas$})
    end

    it 'assigns top level attributes' do
      expect(canvas).to have_attributes(label: 'Front', height: 238, width: 400)
    end

    it 'includes image annotation' do
      expect(canvas.images.first).to be_a IIIF::Presentation::Annotation
    end

    it 'includes image resource within annotation' do
      expect(canvas.images.first.resource['@id']).to start_with("#{Settings.image_server.url}/iiif/2")
      expect(canvas.images.first.resource).to have_attributes(width: 400, height: 238)
    end

    it 'includes original image download' do
      expect(canvas['rendering']).to be_an(Array)
      expect(canvas['rendering'][0]).to include(
        '@id' => match(%r{/v1/assets/.+/preservation$}),
        'label' => 'Original File - 291 KB',
        'format' => 'image/tiff'
      )
    end

    context 'when asset does not have a label' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

      it 'generates label based on index' do
        expect(canvas).to have_attributes('label' => 'p. 1')
      end
    end
  end
end
