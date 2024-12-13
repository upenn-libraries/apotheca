# frozen_string_literal: true

describe GenerateDerivatives do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:item) { persist(:item_resource, :with_full_asset, :with_bibnumber) }
    let(:result) { transaction.call(id: item.asset_ids.first, updated_by: 'initiator@example.com') }

    include_context 'with successful Marmite request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    end

    context 'when derivatives not present' do
      include_examples 'creates a resource event', :generate_derivatives, 'initiator@example.com', true do
        let(:resource) { updated_asset }
      end

      it 'generates and adds derivatives' do
        expect(updated_asset.derivatives.length).to be 5
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly('thumbnail', 'access', 'textonly_pdf',
                                                                         'text', 'hocr')
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
        expect(updated_asset.derivatives.count).to be 5
        expect(updated_asset.derivatives.map(&:generated_at)).to all(be_within(1.second).of(DateTime.current))
      end
    end
  end
end
