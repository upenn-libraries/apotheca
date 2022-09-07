# frozen_string_literal: true

describe Asset do
  let(:file1) { ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/front.jpg')) }
  let(:file2) { ActionDispatch::Http::UploadedFile.new tempfile: File.open(file_fixture('files/bell.wav')) }

  describe '.create' do
    subject(:asset) do
      described_class.create(file: file1, original_filename: 'front.jpg', created_by: 'admin@library.upenn.edu')
    end

    it 'sets technical metadata' do
      expect(asset.technical_metadata.mime_type).to eql 'image/jpeg'
      expect(asset.technical_metadata.size).to be 42_421
      expect(asset.technical_metadata.md5).to eql 'a93d8dc6bc83cd51ad60a151a8ce11e4'
    end

    it 'sets sha256 checksum' do
      expect(asset.technical_metadata.sha256).to eql 'd58516c7d3ece4d79f0de3a649a090af2174e67b7658f336a027a42123a2da72'
    end

    it 'generates and adds derivatives' do
      expect(asset.derivatives.length).to be 2
      expect(asset.derivatives.map(&:type)).to contain_exactly 'thumbnail', 'access'
    end
  end

  describe '.update' do
    let(:asset) do
      described_class.create(file: file1, original_filename: 'front.jpg', created_by: 'admin@library.upenn.edu')
    end

    context 'when updating file' do
      subject(:updated_asset) { described_class.new(asset).update(file: file2) }

      it 'updates technical metadata' do
        expect(updated_asset.technical_metadata.mime_type).to eql 'audio/x-wave'
        expect(updated_asset.technical_metadata.size).to be 30_804
        expect(updated_asset.technical_metadata.md5).to eql '79a2f8e83b4babe41ba0b5458e3d1e4a'
      end

      it 'updates checksum' do
        expect(
          updated_asset.technical_metadata.sha256
        ).to eql '16c93ccb293cf3ea20fee8df210ac351365322745a6d626638d091dfc52f200e'
      end

      it 'updates derivatives' do
        expect(updated_asset.derivatives.length).to be 0
      end
    end
  end
end
