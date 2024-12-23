# frozen_string_literal: true

describe GenerateDerivatives do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:asset) { persist(:asset_resource, :with_preservation_file, :with_metadata) }
    let(:item) { persist(:item_resource, asset_ids: [asset.id]) }
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

    context 'when item descriptive metadata has a valid language' do
      let(:item) do
        persist(:item_resource, descriptive_metadata: { language: [{ value: 'English' }, { value: 'German' }] },
                                asset_ids: [asset.id])
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
        persist(:item_resource, descriptive_metadata: { bibnumber: [{ value: 'sample-bib' }] }, asset_ids: [asset.id])
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
  end
end
