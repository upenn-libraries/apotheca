# frozen_string_literal: true

describe PostgresQueries::TechnicalMetadata do
  let(:query) do
    described_class.new(query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service)
  end

  describe '#assets_without_dpi' do
    context 'when all assets have dpi' do
      before { persist(:asset_resource, :with_image_file) }

      it 'returns no assets' do
        expect(query.assets_without_dpi.count).to eq 0
      end
    end

    context 'when some assets are missing dpi' do
      let(:technical_metadata) { build(:asset_resource, :with_image_file).technical_metadata.to_h }
      let!(:asset_ids) do
        [
          persist(:asset_resource, :with_image_file, technical_metadata: technical_metadata.merge(dpi: nil)),
          persist(:asset_resource, :with_image_file, technical_metadata: technical_metadata.except(:dpi))
        ].map(&:id)
      end

      it 'returns assets that are missing dpi' do
        expect(query.assets_without_dpi.map(&:id)).to match_array asset_ids
      end
    end

    context 'when there are non image assets' do
      before { persist(:asset_resource, :with_video_file) }

      it 'returns no assets' do
        expect(query.assets_without_dpi.count).to eq 0
      end
    end
  end

  describe '#assets_by_mime_types' do
    let(:video_asset) { persist(:asset_resource, :with_video_file) }
    let(:image_asset) { persist(:asset_resource, :with_image_file) }
    let(:audio_asset) { persist(:asset_resource, :with_audio_file) }

    before do
      video_asset
      image_asset
      audio_asset
    end

    context 'when one mime type provided' do
      it 'returns matching asset' do
        expect(query.assets_by_mime_types('video/quicktime').map(&:id)).to contain_exactly(video_asset.id)
      end
    end

    context 'when multiple mime types provided' do
      it 'returns matching assets' do
        expect(
          query.assets_by_mime_types('video/quicktime', 'image/tiff').map(&:id)
        ).to contain_exactly(video_asset.id, image_asset.id)
      end
    end

    context 'when no assets with matching mime types present' do
      it 'returns empty array' do
        expect(query.assets_by_mime_types('application/pdf').to_a).to be_blank
      end
    end
  end
end
