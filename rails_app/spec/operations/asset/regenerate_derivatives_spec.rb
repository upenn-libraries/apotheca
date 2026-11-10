# frozen_string_literal: true

describe Asset::RegenerateDerivatives do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:operation) { described_class.new }
    let(:asset) { persist(:asset_resource, :with_image_file, :with_metadata) }
    let(:item) { persist(:item_resource, :printed, asset_ids: [asset.id]) }
    let(:result) { operation.call(item.asset_ids.first, 'initiator@example.com') }

    context 'when derivatives not present' do
      include_examples 'creates a resource event', :generate_derivatives, 'initiator@example.com', false do
        let(:resource) { updated_asset }
      end

      it 'generates and adds derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'iiif_image')
      end
    end

    context 'when derivatives already present' do
      before do
        travel_to(1.minute.ago) do
          operation.call(item.asset_ids.first, 'initiator@example.com')
        end
      end

      include_examples 'creates a resource event', :generate_derivatives, 'initiator@example.com', false do
        let(:resource) { updated_asset }
      end

      it 'regenerates derivatives' do
        expect(updated_asset.derivatives.count).to be 2
        expect(updated_asset.derivatives.map(&:generated_at)).to all(be_within(1.second).of(DateTime.current))
      end
    end

    context 'when ocr_strategy is blank' do
      let(:item) { persist(:item_resource, ocr_strategy: nil, asset_ids: [asset.id]) }

      it 'does not generate OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'iiif_image')
      end
    end

    context 'when asset has no parent Item' do
      let(:result) { operation.call(asset.id, 'initiator@example.com') }

      it 'returns a failure' do
        expect(result).to be_failure
        expect(result.failure[:error]).to eq(:asset_has_no_parent_item)
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
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'iiif_image', 'textonly_pdf',
                                                                         'text', 'hocr')
      end
    end

    context 'when language metadata is only found in ils metadata' do
      include_context 'with successful Alma request' do
        let(:xml) { File.read(file_fixture('alma/marc_xml/book-1.xml')) }
      end

      let(:item) do
        persist(:item_resource, :printed, descriptive_metadata: {
                  bibnumber: [{ value: MMSIDValidator::EXAMPLE_VALID_MMS_ID }]
                }, asset_ids: [asset.id])
      end

      it 'generates OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 5
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'iiif_image',
                                                                         'textonly_pdf', 'text', 'hocr')
      end
    end

    context 'when there is no language metadata' do
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'does not generate OCR derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('iiif_image', 'thumbnail')
      end
    end
  end
end
