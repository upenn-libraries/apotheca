# frozen_string_literal: true

require_relative 'concerns/modification_details'
require_relative 'concerns/lockable'

describe AssetResource do
  let(:resource_klass) { described_class }
  let(:resource) { build(:asset_resource) }

  it_behaves_like 'a Valkyrie::Resource'
  it_behaves_like 'ModificationDetails', :asset_resource
  it_behaves_like 'Lockable', :asset_resource

  describe '.pyramidal_tiff' do
    context 'when the iiif_image derivative is present' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

      it 'returns the iiif_image derivative' do
        expect(asset.pyramidal_tiff).to eq(asset.iiif_image)
      end
    end

    context 'when the iiif_image derivative is present for video file' do
      let(:asset) { persist(:asset_resource, :with_video_file, :with_derivatives) }

      it 'returns the iiif_image derivative' do
        expect(asset.pyramidal_tiff).to eq(asset.iiif_image)
      end
    end

    context 'when the iiif_image derivative is not present but the access image derivative is' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

      before do
        iiif_image = asset.derivatives.find(&:iiif_image?)
        iiif_image.type = 'access'
        asset.derivatives = [iiif_image]
      end

      it 'returns the fallback access derivative' do
        expect(asset.pyramidal_tiff).to eq(asset.access)
      end
    end
  end
end
