# frozen_string_literal: true

describe DerivativeService::Asset::Generator::Audio do
  let(:file) { Valkyrie::StorageAdapter::StreamFile.new id: 1, io: File.open(file_fixture('files/bell.wav')) }
  let(:generator) { described_class.new(file) }

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
