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
      subject(:metadata) { fits.examine(contents: file_contents, filename: 'front.jpg') }

      let(:file_contents) { File.read(file_fixture('files/front.jpg')) }
      let(:technical_metadata) do
        <<~METADATA
          <?xml version="1.0" encoding="UTF-8"?>
          <fits xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd" version="1.5.0" timestamp="3/1/22 9:04 PM">
            <identification status="SINGLE_RESULT">
              <identity format="JPEG EXIF" mimetype="image/jpeg" toolname="FITS" toolversion="1.5.0">
                <tool toolname="Exiftool" toolversion="11.54" />
                <version toolname="Exiftool" toolversion="11.54">1.01</version>
              </identity>
            </identification>
            <fileinfo>
              <size toolname="Jhove" toolversion="1.20.1">42421</size>
              <filename toolname="OIS File Information" toolversion="1.0" status="SINGLE_RESULT">front.jpg</filename>
              <md5checksum toolname="OIS File Information" toolversion="1.0" status="SINGLE_RESULT">a93d8dc6bc83cd51ad60a151a8ce11e4</md5checksum>
              <fslastmodified toolname="OIS File Information" toolversion="1.0" status="SINGLE_RESULT">1646168644000</fslastmodified>
            </fileinfo>
            <filestatus />
            <metadata>
              <image>
                <imageWidth toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">500</imageWidth>
                <imageHeight toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">297</imageHeight>
                <iccProfileName toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">Adobe RGB (1998)</iccProfileName>
                <iccProfileVersion toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">2.1.0</iccProfileVersion>
                <YCbCrSubSampling toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">2 2</YCbCrSubSampling>
                <samplingFrequencyUnit toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">in.</samplingFrequencyUnit>
                <xSamplingFrequency toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">600</xSamplingFrequency>
                <ySamplingFrequency toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">600</ySamplingFrequency>
                <bitsPerSample toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">8 8 8</bitsPerSample>
                <exifVersion toolname="Exiftool" toolversion="11.54" status="SINGLE_RESULT">0221</exifVersion>
              </image>
            </metadata>
          </fits>
        METADATA
      end

      it { is_expected.to be_an_instance_of FileCharacterization::Fits::Metadata }

      it 'contains raw metadata' do
        expect(metadata.raw).to be_a String
      end

      it 'returns mime type' do
        expect(metadata.mime_type).to eql 'image/jpeg'
      end

      it 'returns size' do
        expect(metadata.size).to be 42_421
      end

      it 'returns duration' do
        expect(metadata.duration).to be_nil
      end

      it 'returns md5 checksum' do
        expect(metadata.md5).to eql 'a93d8dc6bc83cd51ad60a151a8ce11e4'
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
