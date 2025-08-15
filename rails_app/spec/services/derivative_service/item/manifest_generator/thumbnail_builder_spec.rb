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

    it 'builds thumbnail' do
      expect(thumbnail).to be_a Hash
    end

    it 'assigns ID' do
      expect(thumbnail).to include(
        'id' => starting_with("#{Settings.image_server.url}/iiif/3")
                   .and(ending_with('/full/!200,200/0/default.jpg'))
      )
    end

    it 'assigns type' do
      expect(thumbnail).to include(
        'type' => 'Image'
      )
    end

    it 'assigns format' do
      expect(thumbnail).to include(
        'format' => 'image/jpeg'
      )
    end

    it 'assigns service' do
      expect(thumbnail['service']).to contain_exactly(
        {
          'id' => starting_with("#{Settings.image_server.url}/iiif/3").and(ending_with('iiif_image')),
          'type' => 'ImageService3',
          'profile' => 'level2'
        }
      )
    end
  end
end
