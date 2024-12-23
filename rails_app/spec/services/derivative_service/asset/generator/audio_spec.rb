# frozen_string_literal: true

describe DerivativeService::Asset::Generator::Audio do
  let(:resource) { persist(:asset_resource, :with_preservation_file, :with_audio_file) }
  let(:generator) { described_class.new(AssetChangeSet.new(resource)) }

  describe '#access' do
    subject(:derivative_file) { generator.access }

    it 'returns DerivativeFile' do
      expect(derivative_file).to be_a DerivativeService::DerivativeFile
    end

    it 'sets expected mime_type' do
      expect(derivative_file.mime_type).to eql 'audio/mpeg'
    end

    it 'adds file' do
      expect(derivative_file.length).not_to be 0
    end
  end
end
