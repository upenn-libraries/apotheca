# frozen_string_literal: true

describe FileCharacterization::Fits do
  describe '.new' do
    subject(:fits) { described_class.new(url: url) }

    let(:url) { Settings.fits.url }

    it { is_expected.to be_a described_class }

    it 'sets url' do
      expect(fits.url).to eql url
    end
  end

  describe '#examine' do
    let(:fits) { described_class.new(url: Settings.fits.url) }

    context 'with tiff file' do
      subject(:metadata) { fits.examine(contents: file_contents, filename: 'front.tif') }

      let(:file_contents) { File.read(file_fixture('files/trade_card/original/front.tif')) }

      it { is_expected.to be_an_instance_of FileCharacterization::Fits::Metadata }

      it 'contains raw metadata' do
        expect(metadata.raw).to be_a String
      end

      it 'returns mime type' do
        expect(metadata.mime_type).to eql 'image/tiff'
      end

      it 'returns size' do
        expect(metadata.size).to be 291_455
      end

      it 'returns width' do
        expect(metadata.width).to be 400
      end

      it 'returns height' do
        expect(metadata.height).to be 238
      end

      it 'returns duration' do
        expect(metadata.duration).to be_nil
      end

      it 'returns md5 checksum' do
        expect(metadata.md5).to eql 'c2c44072c0ec08013cff72aa7dc8d405'
      end
    end

    context 'with wav file' do
      subject(:metadata) { fits.examine(contents: file_contents, filename: 'bell.wav') }

      let(:file_contents) { File.read(file_fixture('files/bell.wav')) }

      it 'contains raw metadata' do
        expect(metadata.raw).to be_a String
      end

      it 'returns mime type' do
        expect(metadata.mime_type).to eql 'audio/x-wave'
      end

      it 'returns size' do
        expect(metadata.size).to be 30_804
      end

      it 'returns width' do
        expect(metadata.width).to be_nil
      end

      it 'returns height' do
        expect(metadata.height).to be_nil
      end

      it 'returns duration' do
        expect(metadata.duration).to eql 0.17
      end

      it 'returns md5 checksum' do
        expect(metadata.md5).to eql '79a2f8e83b4babe41ba0b5458e3d1e4a'
      end
    end

    context 'with video file' do
      subject(:metadata) { fits.examine(contents: file_contents, filename: 'video.mov') }

      let(:file_contents) { File.read(file_fixture('files/video.mov')) }

      it 'contains raw metadata' do
        expect(metadata.raw).to be_a String
      end

      it 'returns mime type' do
        expect(metadata.mime_type).to eql 'video/quicktime'
      end

      it 'returns size' do
        expect(metadata.size).to be  480_754
      end

      it 'returns width' do
        expect(metadata.width).to be 640
      end

      it 'returns height' do
        expect(metadata.height).to be 480
      end

      # Skipping this test on ARM architecture because the MediaInfo binary used by FITS does not support
      # Linux-based ARM Architectures. It would be hard to fix this problem now, we should wait until the
      # Ubuntu version of MediaInfo supports ARM.
      it 'returns duration', skip_on_arm: true do
        expect(metadata.duration).to eql 1.134
      end

      it 'returns md5 checksum' do
        expect(metadata.md5).to eql '0c77b046855997e15f059c61b0084a43'
      end
    end
  end
end
