# frozen_string_literal: true

describe Asset do
  describe '.create' do
    subject(:asset) { described_class.create(file: file, original_filename: 'front.jpg') }

    let(:file) { ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/front.jpg')) }

    it 'sets technical metadata' do
      expect(asset.technical_metadata.mime_type).to eql 'image/jpeg'
      expect(asset.technical_metadata.size).to eql 42_421
      expect(asset.technical_metadata.md5).to eql 'a93d8dc6bc83cd51ad60a151a8ce11e4'
    end
  end

  describe '.update'
end