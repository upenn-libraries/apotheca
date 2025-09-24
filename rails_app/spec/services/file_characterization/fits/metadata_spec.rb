# frozen_string_literal: true

describe FileCharacterization::Fits::Metadata do
  subject(:metadata) { described_class.new(xml) }

  describe '#dpi' do
    let(:xml) do
      <<~XML
        <fits xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd" version="1.6.0" timestamp="9/23/25, 5:30 PM">
          <identification>
            <identity format="TIFF EXIF" mimetype="image/tiff" toolname="FITS" toolversion="1.6.0"></identity>
          </identification>
          <metadata>
            <image>
              #{sampling_frequency_xml}
            </image>
          </metadata>
        </fits>
      XML
    end

    context 'when sampling frequency in inches' do
      let(:sampling_frequency_xml) do
        <<~SAMPLINGFREQUENCY
          <samplingFrequencyUnit toolname="Jhove" toolversion="1.26.1">in.</samplingFrequencyUnit>
          <xSamplingFrequency toolname="Exiftool" toolversion="12.50">600</xSamplingFrequency>
          <ySamplingFrequency toolname="Exiftool" toolversion="12.50">600</ySamplingFrequency>
        SAMPLINGFREQUENCY
      end

      it 'correctly extracts dpi' do
        expect(metadata.dpi).to be 600
      end
    end

    context 'when sampling frequency in centimeters' do
      let(:sampling_frequency_xml) do
        <<~SAMPLINGFREQUENCY
          <samplingFrequencyUnit toolname="Jhove" toolversion="1.26.1">cm</samplingFrequencyUnit>
          <xSamplingFrequency toolname="Exiftool" toolversion="12.50">236</xSamplingFrequency>
          <ySamplingFrequency toolname="Exiftool" toolversion="12.50">236</ySamplingFrequency>
        SAMPLINGFREQUENCY
      end

      it 'converts to inches' do
        expect(metadata.dpi).to be 599
      end
    end

    context 'when sampling frequency contains non-digit characters' do
      let(:sampling_frequency_xml) do
        <<~SAMPLINGFREQUENCY
          <xSamplingFrequency toolname="Exiftool" toolversion="12.50" status="CONFLICT">1.039800048</xSamplingFrequency>
          <xSamplingFrequency toolname="Tika" toolversion="2.6.0" status="CONFLICT">1.0398000478744507</xSamplingFrequency>
          <ySamplingFrequency toolname="Exiftool" toolversion="12.50" status="CONFLICT">1.039800048</ySamplingFrequency>
          <ySamplingFrequency toolname="Tika" toolversion="2.6.0" status="CONFLICT">1.0398000478744507</ySamplingFrequency>
        SAMPLINGFREQUENCY
      end

      it 'returns nil' do
        expect(metadata.dpi).to be_nil
      end
    end

    context 'when sampling frequency is zero' do
      let(:sampling_frequency_xml) do
        <<~SAMPLINGFREQUENCY
          <samplingFrequencyUnit toolname="Jhove" toolversion="1.26.1">in.</samplingFrequencyUnit>
          <xSamplingFrequency toolname="Jhove" toolversion="1.26.1" status="CONFLICT">0</xSamplingFrequency>
          <ySamplingFrequency toolname="Jhove" toolversion="1.26.1" status="CONFLICT">0</ySamplingFrequency>
        SAMPLINGFREQUENCY
      end

      it 'returns nil' do
        expect(metadata.dpi).to be_nil
      end
    end

    context 'when multiple sampling frequencies are present' do
      let(:sampling_frequency_xml) do
        <<~SAMPLINGFREQUENCY
          <samplingFrequencyUnit toolname="Jhove" toolversion="1.26.1">in.</samplingFrequencyUnit>
          <xSamplingFrequency toolname="Jhove" toolversion="1.26.1" status="CONFLICT">0</xSamplingFrequency>
          <xSamplingFrequency toolname="Exiftool" toolversion="12.50" status="CONFLICT">350</xSamplingFrequency>
          <xSamplingFrequency toolname="Tika" toolversion="2.6.0" status="CONFLICT">350.0</xSamplingFrequency>
          <ySamplingFrequency toolname="Jhove" toolversion="1.26.1" status="CONFLICT">0</ySamplingFrequency>
          <ySamplingFrequency toolname="Exiftool" toolversion="12.50" status="CONFLICT">350</ySamplingFrequency>
          <ySamplingFrequency toolname="Tika" toolversion="2.6.0" status="CONFLICT">350.0</ySamplingFrequency>
        SAMPLINGFREQUENCY
      end

      it 'extracts the best dpi' do
        expect(metadata.dpi).to be 350
      end
    end

    context 'when sampling frequency is not present' do
      let(:sampling_frequency_xml) { '' }

      it 'returns nil' do
        expect(metadata.dpi).to be_nil
      end
    end
  end
end
