# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::ThumbnailBuilder do
  describe '#build' do
    let(:access_derivative) do
      asset = persist(:asset_resource, :with_image_file, :with_derivatives)
      iiif_image = asset.derivatives.find(&:iiif_image?)
      iiif_image.type = 'access'
      [iiif_image]
    end
    let(:asset) { persist(:asset_resource, :with_image_file, derivatives: access_derivative) }
    let(:thumbnail) { described_class.new(asset).build }

    it 'assigns top-level attributes' do
      expect(thumbnail).to include(
        'id' => ending_with('/full/!200,200/0/default.jpg'),
        'type' => 'Image',
        'format' => 'image/jpeg',
        'service' => [include(
          'id' => ending_with('iiif_image'),
          'type' => 'ImageService3',
          'profile' => 'level2'
        )]
      )
    end
  end
end
