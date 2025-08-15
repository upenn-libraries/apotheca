# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::CanvasBuilder do
  describe '#build' do
    let(:access_derivative) do
      asset = persist(:asset_resource, :with_image_file, :with_derivatives)
      iiif_image = asset.derivatives.find(&:iiif_image?)
      iiif_image.type = 'access'
      [iiif_image]
    end
    let(:asset) { persist(:asset_resource, :with_image_file, derivatives: access_derivative) }
    let(:canvas) { described_class.new(asset, 1).build }

    context 'with a canvas' do
      it 'builds canvas' do
        expect(canvas).to be_a IIIF::V3::Presentation::Canvas
      end

      it 'assigns attributes' do
        expect(canvas).to have_attributes(
          'id' => ending_with('canvas'),
          'items' => all(be_a(IIIF::V3::Presentation::AnnotationPage))
        )
      end
    end

    context 'with an annotation-page' do
      it 'assigns attributes' do
        expect(canvas.items.first).to have_attributes(
          'id' => ending_with('annotation-page/1')
        )
      end
    end

    context 'with an annotation' do
      it 'adds annotation to annotation-page items' do
        expect(canvas.items.first.items).to be_an Array
        expect(canvas.items.first.items.first).to be_a IIIF::V3::Presentation::Annotation
      end

      it 'assigns attributes' do
        expect(canvas.items.first.items.first).to have_attributes(
          'id' => ending_with('annotation/1'),
          'motivation' => 'painting',
          'target' => canvas.id,
          'body' => be_a(IIIF::V3::Presentation::ImageResource)
        )
      end
    end

    context 'with an image resource' do
      it 'assigns attributes' do
        expect(canvas.items.first.items.first.body).to have_attributes(
          'id' => end_with('iiif_image/full/!200,200/0/default.jpg'),
          'width' => be_an(Integer),
          'height' => be_an(Integer)
        )
        expect(canvas.items.first.items.first.body.service.first).to have_attributes(
          'profile' => 'level2',
          'type' => 'ImageService3'
        )
      end
    end

    context 'with a placeholder canvas' do
      it 'builds placeholder canvas' do
        expect(canvas['placeholderCanvas']).to be_a IIIF::V3::Presentation::Canvas
      end

      it 'assigns top level attributes' do
        expect(canvas['placeholderCanvas']).to have_attributes(
          'id' => ending_with('canvas/placeholder'),
          'label' => { 'none' => ['p. 1'] }
        )
      end

      it 'assigns items' do
        expect(canvas['placeholderCanvas'].items.first).to be_a IIIF::V3::Presentation::AnnotationPage
      end

      it 'assigns annotation-page attributes' do
        expect(canvas['placeholderCanvas'].items.first).to have_attributes(
          'id' => ending_with('canvas/placeholder/annotation-page')
        )
      end

      it 'assigns annotation-page items' do
        expect(canvas['placeholderCanvas'].items.first.items.first).to be_a IIIF::V3::Presentation::Annotation
      end
    end

    context 'with placeholder canvas annotation' do
      it 'assigns attributes' do
        expect(canvas['placeholderCanvas'].items.first.items.first).to have_attributes(
          'id' => end_with('canvas/placeholder/annotation-page/1'),
          'motivation' => 'painting',
          'target' => end_with('canvas/placeholder'),
          'body' => be_a(IIIF::V3::Presentation::ImageResource)
        )
      end
    end

    context 'with placeholder image resource' do
      it 'assigns attributes' do
        expect(canvas['placeholderCanvas'].items.first.items.first.body).to have_attributes(
          'id' => end_with('iiif_image/full/640,/0/default.jpg'),
          'width' => be_an(Integer),
          'height' => be_an(Integer)
        )
        expect(canvas['placeholderCanvas'].items.first.items.first.body.service.first).to have_attributes(
          'profile' => 'level2',
          'type' => 'ImageService3'
        )
      end
    end

    context 'with original file rendering' do
      it 'assigns attributes' do
        expect(canvas['rendering']).to be_an(Array).and include(
          a_hash_including(
            'id' => a_string_ending_with('preservation'),
            'label' => { 'en' => ['Original File - 291 KB'] },
            'type' => 'Image',
            'format' => 'image/tiff'
          )
        )
      end
    end
  end
end
