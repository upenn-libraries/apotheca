# frozen_string_literal: true

describe Asset do
  describe '.create' do
    subject(:asset) do
      described_class.create(file: file, original_filename: 'front.jpg', created_by: 'admin@library.upenn.edu')
    end

    let(:file) { ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/front.jpg')) }

    it 'sets technical metadata' do
      expect(asset.technical_metadata.mime_type).to eql 'image/jpeg'
      expect(asset.technical_metadata.size).to be 42_421
      expect(asset.technical_metadata.md5).to eql 'a93d8dc6bc83cd51ad60a151a8ce11e4'
    end

    it 'sets sha256 checksum' do
      expect(asset.technical_metadata.sha256).to eql 'd58516c7d3ece4d79f0de3a649a090af2174e67b7658f336a027a42123a2da72'
    end
  end

  describe '.update'
end
