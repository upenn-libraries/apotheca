# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::ThumbnailBuilder do
  describe '#build' do
    let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }
    let(:thumbnail) { described_class.new(asset).build }

    it 'assigns top-level attributes' do
      expect(thumbnail).to include(
        'id' => ending_with('/full/!200,200/0/default.jpg'),
        'type' => 'Image',
        'format' => 'image/jpeg',
        'service' => [include(
          'id' => ending_with(asset.id.to_s),
          'type' => 'ImageService3',
          'profile' => 'level2'
        )]
      )
    end
  end
end
