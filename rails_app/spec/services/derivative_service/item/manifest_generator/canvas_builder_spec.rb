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
    let(:index) { 1 }
    let(:canvas) { described_class.new(asset, index).build }

    let(:annotations) { canvas.items.first.items }
    let(:annotation) { annotations.first }
    let(:image_resource) { annotation.body }

    let(:annotation_page) { canvas.items.first }

    let(:placeholder_canvas_annotation_page) { canvas['placeholderCanvas'].items.first }
    let(:placeholder_canvas_annotation) { placeholder_canvas_annotation_page.items.first }
    let(:placeholder_image_resource) { placeholder_canvas_annotation.body }

    context 'with a canvas' do
      it 'builds canvas' do
        expect(canvas).to be_a IIIF::V3::Presentation::Canvas
      end

      it 'assigns id' do
        expect(canvas.id).to start_with("https://#{Settings.app_url}")
          .and(end_with('canvas'))
      end
    end

    context 'with an annotation-page' do
      it 'adds annotation-page to canvas items' do
        expect(annotation_page).to be_a IIIF::V3::Presentation::AnnotationPage
      end

      it 'assigns id' do
        expect(annotation_page.id).to start_with("https://#{Settings.app_url}")
          .and(ending_with("annotation-page/#{index}"))
      end
    end

    context 'with an annotation' do
      it 'adds annotation to annotation-page items' do
        expect(annotations).to be_an Array
        expect(annotation).to be_a IIIF::V3::Presentation::Annotation
      end

      it 'assigns id' do
        expect(annotation.id).to start_with("https://#{Settings.app_url}")
          .and(ending_with('annotation/1'))
      end

      it 'assigns motivation' do
        expect(annotation.motivation).to eq 'painting'
      end

      it 'assigns target' do
        expect(annotation.target).to eq canvas.id
      end

      it 'assigns body' do
        expect(annotation.body).to be_a IIIF::V3::Presentation::ImageResource
      end
    end

    context 'with an image resource' do
      it 'assigns id' do
        expect(image_resource.id).to end_with('iiif_image/full/!200,200/0/default.jpg')
      end

      it 'assigns width' do
        expect(image_resource.width).to be_an Integer
      end

      it 'assigns height' do
        expect(image_resource.height).to be_an Integer
      end

      it 'assigns profile' do
        expect(image_resource.service.first.profile).to include 'level2'
      end

      it 'assigns service type' do
        expect(image_resource.service.first.type).to eq 'ImageService3'
      end
    end

    context 'with a placeholder canvas' do
      it 'builds placeholder canvas' do
        expect(canvas['placeholderCanvas']).to be_a IIIF::V3::Presentation::Canvas
      end

      it 'assigns id' do
        expect(canvas['placeholderCanvas'].id).to end_with('canvas/placeholder')
      end

      it 'assigns label' do
        expect(canvas['placeholderCanvas'].label).to eq({ 'none' => ['p. 1'] })
      end

      it 'assigns items' do
        expect(canvas['placeholderCanvas'].items).to be_an Array
        expect(placeholder_canvas_annotation_page).to be_an IIIF::V3::Presentation::AnnotationPage
      end

      it 'assigns annotation-page id' do
        expect(placeholder_canvas_annotation_page.id).to end_with('placeholder/annotation-page')
      end

      it 'assigns annotation-page items' do
        expect(placeholder_canvas_annotation).to be_a IIIF::V3::Presentation::Annotation
      end
    end

    context 'with placeholder canvas annotation' do
      it 'assigns id' do
        expect(placeholder_canvas_annotation.id).to end_with('canvas/placeholder/annotation-page/1')
      end

      it 'assigns motivation' do
        expect(placeholder_canvas_annotation.motivation).to eq 'painting'
      end

      it 'assigns target' do
        expect(placeholder_canvas_annotation.target).to end_with('canvas/placeholder')
      end

      it 'assigns body' do
        expect(placeholder_canvas_annotation.body).to be_a IIIF::V3::Presentation::ImageResource
      end
    end

    context 'with placeholder image resource' do
      it 'assigns id' do
        expect(placeholder_image_resource.id)
          .to end_with('iiif_image/full/640,/0/default.jpg')
      end

      it 'assigns width' do
        expect(placeholder_image_resource.width).to be_an Integer
      end

      it 'assigns height' do
        expect(placeholder_image_resource.height).to be_an Integer
      end

      it 'assigns profile' do
        expect(placeholder_image_resource.service.first.profile).to include 'level2'
      end

      it 'assigns service type' do
        expect(placeholder_image_resource.service.first.type).to eq 'ImageService3'
      end
    end

    context 'with rendering' do
      it 'builds rendering' do
        expect(canvas['rendering']).to be_an Array
      end

      it 'assigns id' do
        expect(canvas['rendering'].first['id']).to end_with('preservation')
      end

      it 'assigns label' do
        expect(canvas['rendering'].first['label']).to eq({ 'en' => ['Original File - 291 KB'] })
      end

      it 'assigns type' do
        expect(canvas['rendering'].first['type']).to eq 'Image'
      end

      it 'assigns format' do
        expect(canvas['rendering'].first['format']).to eq 'image/tiff'
      end
    end
  end
end
