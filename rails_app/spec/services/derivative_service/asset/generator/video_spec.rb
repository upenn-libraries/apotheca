# frozen_string_literal: true

describe DerivativeService::Asset::Generator::Video do
  let(:resource) { persist(:asset_resource, :with_preservation_file, :with_video_file) }
  let(:generator) { described_class.new(AssetChangeSet.new(resource)) }

  describe '#thumbnail' do
    subject(:derivative_file) { generator.thumbnail }

    it 'returns DerivativeFile' do
      expect(derivative_file).to be_a DerivativeService::DerivativeFile
    end

    it 'sets expected mime_type' do
      expect(derivative_file.mime_type).to eql 'image/jpeg'
    end

    it 'sets expected iiif_image value of false' do
      expect(derivative_file.iiif_image).to be false
    end

    it 'adds file' do
      expect(derivative_file.length).not_to be 0
    end
  end

  describe '#access' do
    subject(:derivative_file) { generator.access }

    it 'returns DerivativeFile' do
      expect(derivative_file).to be_a DerivativeService::DerivativeFile
    end

    it 'sets expected mime_type' do
      expect(derivative_file.mime_type).to eql 'video/mp4'
    end

    it 'adds file' do
      expect(derivative_file.length).not_to be 0
    end
  end
end
