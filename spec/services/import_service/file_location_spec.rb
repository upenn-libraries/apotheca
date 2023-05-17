# frozen_string_literal: true

describe ImportService::FileLocation do
  let(:storage) { ImportService::S3Storage.new('sceti_digitized') }
  let(:file_location) { described_class.new(storage: storage, path: 'trade_card/front.tif') }

  describe '#file?' do
    it 'returns file' do
      expect(file_location.file).to be_a ImportService::S3Storage::File
    end
  end

  describe '#checksum_sha256' do
    it 'returns checksum' do
      expect(file_location.checksum_sha256).to eq '0929169032ec29557bf85b05b82923fdb75694393e34f652b8955912376e1e0b'
    end
  end
end
