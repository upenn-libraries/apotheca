# frozen_string_literal: true

describe GenerateDerivatives do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:asset) { persist(:asset_resource, :with_image_file, :with_metadata) }
    let(:item) { persist(:item_resource, :printed, asset_ids: [asset.id]) }
    let(:result) { transaction.call(id: item.asset_ids.first, updated_by: 'initiator@example.com') }

    context 'when derivatives not present' do
      include_examples 'creates a resource event', :generate_derivatives, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'generates and adds derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'access')
      end
    end

    context 'when derivatives already present' do
      before do
        travel_to(1.minute.ago) do
          transaction.call(id: item.asset_ids.first)
        end
      end

      include_examples 'creates a resource event', :generate_derivatives, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'regenerates derivatives' do
        expect(updated_asset.derivatives.count).to be 2
        expect(updated_asset.derivatives.map(&:generated_at)).to all(be_within(1.second).of(DateTime.current))
      end
    end

    context 'when ocr_type is blank' do
      let(:item) { persist(:item_resource, ocr_type: nil, asset_ids: [asset.id]) }

      it 'does not generate OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'access')
      end
    end

    context 'when item descriptive metadata has a valid language' do
      let(:item) do
        persist(
          :item_resource, :printed, asset_ids: [asset.id],
                                    descriptive_metadata: { language: [{ value: 'English' }, { value: 'German' }] }
        )
      end

      it 'generates OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 5
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'access', 'textonly_pdf',
                                                                         'text', 'hocr')
      end
    end

    context 'when language metadata is only found in ils metadata' do
      include_context 'with successful Marmite request' do
        let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
      end

      let(:item) do
        persist(:item_resource, :printed, descriptive_metadata: {
                  bibnumber: [{ value: MMSIDValidator::EXAMPLE_VALID_MMS_ID }]
                }, asset_ids: [asset.id])
      end

      it 'generates OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 5
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'access', 'textonly_pdf',
                                                                         'text', 'hocr')
      end
    end

    context 'when there is no language metadata' do
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'does not generate OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('access', 'thumbnail')
      end
    end

    context 'when dpi is not present' do
      let(:fits_xml) do
        <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <fits xmlns="http://hul.harvard.edu/ois/xml/ns/fits/fits_output" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://hul.harvard.edu/ois/xml/ns/fits/fits_output http://hul.harvard.edu/ois/xml/xsd/fits/fits_output.xsd" version="1.6.0" timestamp="1/7/25, 6:09 PM">
          <identification>
            <identity format="TIFF EXIF" mimetype="image/tiff" toolname="FITS" toolversion="1.6.0">
              <tool toolname="Jhove" toolversion="1.26.1"/>
            </identity>
          </identification>
          <metadata>
            <image>
              <samplingFrequencyUnit toolname="Jhove" toolversion="1.26.1">in.</samplingFrequencyUnit>
              <xSamplingFrequency toolname="Exiftool" toolversion="12.50">400</xSamplingFrequency>
              <ySamplingFrequency toolname="Exiftool" toolversion="12.50">400</ySamplingFrequency>
            </image>
          </metadata>
         </fits>
        XML
      end
      let(:asset) do
        persist(:asset_resource, :with_image_file, :with_metadata,
                technical_metadata: { size: 291_455, mime_type: 'image/tiff', sha256: ['sha256checksum'],
                                      height: 238, width: 400, dpi: nil, raw: fits_xml })
      end

      it 'adds dpi' do
        expect(updated_asset.technical_metadata.dpi).to be 400
      end
    end
  end
end
