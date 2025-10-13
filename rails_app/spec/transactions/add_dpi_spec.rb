# frozen_string_literal: true

describe AddDPI do
  let(:transaction) { described_class.new }
  let(:result) { transaction.call(id: asset.id, updated_by: 'initiator@example.com') }
  let(:updated_asset) { result.value! }

  context 'when the asset is not an image' do
    let(:asset) { persist(:asset_resource, :with_audio_file) }

    it 'fails' do
      expect(result.failure?).to be true
    end

    it 'provides the expected error message' do
      expect(result.failure[:error]).to be :adding_dpi_failed
    end
  end

  context 'when the asset has DPI in its technical metadata' do
    let(:technical_metadata) { build(:asset_resource, :with_image_file).technical_metadata.to_h }
    let(:asset) do
      persist(:asset_resource, :with_image_file,
              technical_metadata: technical_metadata.merge(dpi: 400, raw: File.read(file_fixture('fits/image.xml'))))
    end

    include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
      let(:resource) { updated_asset }
    end

    it 'returns successful' do
      expect(result.success?).to be true
    end

    it 'updates the dpi' do
      expect(updated_asset.technical_metadata.dpi).to eq 600
    end
  end

  context 'when the asset has no DPI in its technical metadata' do
    let(:technical_metadata) { build(:asset_resource, :with_image_file).technical_metadata.to_h }
    let(:asset) do
      persist(:asset_resource, :with_image_file,
              technical_metadata: technical_metadata.merge(dpi: nil, raw: File.read(file_fixture('fits/image.xml'))))
    end

    include_examples 'creates a resource event', :update_asset, 'initiator@example.com', true do
      let(:resource) { updated_asset }
    end

    it 'is successful' do
      expect(result.success?).to be true
    end

    it 'adds the dpi to the asset' do
      expect(asset.technical_metadata.dpi).to be_nil
      expect(updated_asset.technical_metadata.dpi).to eq 600
    end
  end
end
