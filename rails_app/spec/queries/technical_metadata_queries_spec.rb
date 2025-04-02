# frozen_string_literal: true

describe TechnicalMetadataQueries do
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
end
