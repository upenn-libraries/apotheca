# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::CanvasBuilder::Placeholder do
  describe '#build' do
    let(:access_derivative) do
      asset = persist(:asset_resource, :with_image_file, :with_derivatives)
      iiif_image = asset.derivatives.find(&:iiif_image?)
      iiif_image.type = 'access'
      [iiif_image]
    end
    let(:asset) { persist(:asset_resource, :with_image_file, derivatives: access_derivative) }
    let(:canvas) { described_class.new(asset, 1).build }

    it 'builds placeholder canvas' do
      expect(canvas).to be_a IIIF::V3::Presentation::Canvas
    end

    it 'assigns top level attributes' do
      expect(canvas).to have_attributes(
        'id' => ending_with('canvas/placeholder'),
        'label' => { 'none' => ['p. 1'] }
      )
    end

    it 'assigns items' do
      expect(canvas.items.first).to be_a IIIF::V3::Presentation::AnnotationPage
    end

    it 'assigns annotation-page attributes' do
      expect(canvas.items.first).to have_attributes(
        'id' => ending_with('canvas/placeholder/annotation-page')
      )
    end

    it 'assigns annotation-page items' do
      expect(canvas.items.first.items.first).to be_a IIIF::V3::Presentation::Annotation
    end

    context 'with placeholder canvas annotation' do
      it 'assigns attributes' do
        expect(canvas.items.first.items.first).to have_attributes(
          'id' => end_with('canvas/placeholder/annotation-page/1'),
          'motivation' => 'painting',
          'target' => end_with('canvas/placeholder'),
          'body' => be_a(IIIF::V3::Presentation::ImageResource)
        )
      end
    end

    context 'with placeholder image resource' do
      it 'assigns attributes' do
        expect(canvas.items.first.items.first.body).to have_attributes(
          'id' => end_with('iiif_image/full/640,/0/default.jpg'),
          'width' => 640,
          'height' => 380
        )
        expect(canvas.items.first.items.first.body.service.first).to have_attributes(
          'profile' => 'level2',
          'type' => 'ImageService3'
        )
      end
    end
  end
end
