# frozen_string_literal: true

describe DerivativeService::Generator::Video do
  let(:file) { Valkyrie::StorageAdapter::StreamFile.new id: 1, io: File.open(file_fixture('files/video.mov')) }
  let(:generator) { described_class.new(file) }

  describe '#thumbnail' do
    subject(:derivative_file) { generator.thumbnail }

    it 'returns DerivativeFile' do
      expect(derivative_file).to be_a DerivativeService::DerivativeFile
    end

    it 'sets expected mime_type' do
      expect(derivative_file.mime_type).to eql 'image/jpeg'
    end

    it 'sets expected iiif value of false' do
      expect(derivative_file.iiif).to be false
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
