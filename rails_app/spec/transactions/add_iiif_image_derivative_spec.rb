# frozen_string_literal: true

describe AddIIIFImageDerivative do
  let(:transaction) { described_class.new }
  let(:result) { transaction.call(id: asset.id, updated_by: 'initiator@example.com') }
  let(:updated_asset) { result.value! }

  context 'when asset is an image-based derivative' do
    include_context 'with access derivative'

    before { freeze_time }
    after  { unfreeze_time }

    let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

    it 'is successful' do
      expect(result.success?).to be true
    end

    it 'keeps other derivatives' do
      expect(asset.derivatives.find(&:access?)).to be_present
      expect(updated_asset.derivatives.map(&:type)).to contain_exactly(
        'thumbnail', 'iiif_image', 'text', 'textonly_pdf', 'hocr'
      )
    end

    it 'removes access derivatives' do
      expect(updated_asset.access).to be_nil
    end

    it 'adds iiif_image derivative' do
      expect(updated_asset.iiif_image).to have_attributes(file_id: an_instance_of(Valkyrie::ID),
                                                          type: 'iiif_image',
                                                          mime_type: 'image/tiff',
                                                          size: an_instance_of(Integer),
                                                          generated_at: DateTime.current)
    end
  end

  context 'when asset is not an image-based derivative' do
    let(:asset) { persist(:asset_resource, :with_video_file, :with_derivatives) }

    it 'fails' do
      expect(result.failure?).to be true
    end

    it 'provides the expected error message' do
      expect(result.failure[:error]).to be :asset_not_an_image
    end
  end

  context 'when asset already has an iiif_image derivative' do
    let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

    it 'fails' do
      expect(result.failure?).to be true
    end

    it 'provides the expected error message' do
      expect(result.failure[:error]).to be :iiif_image_derivative_already_present
    end
  end
end
