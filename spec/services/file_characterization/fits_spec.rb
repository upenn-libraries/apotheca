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

      let(:file_contents) { File.read(file_fixture('files/front.tif')) }

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

      it 'returns duration' do
        expect(metadata.duration).to eql '0.17 s'
      end

      it 'returns md5 checksum' do
        expect(metadata.md5).to eql '79a2f8e83b4babe41ba0b5458e3d1e4a'
      end
    end
  end
end
