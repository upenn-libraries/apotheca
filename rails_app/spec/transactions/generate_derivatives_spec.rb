# frozen_string_literal: true

describe GenerateDerivatives do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:asset) { persist(:asset_resource, :with_preservation_file) }
    let(:result) { transaction.call(id: asset.id, updated_by: asset.updated_by) }

    context 'when derivatives not present' do
      it 'generates and adds derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly 'thumbnail', 'access'
      end
    end

    context 'when derivatives already present' do
      before do
        travel_to(1.minute.ago) do
          transaction.call(id: asset.id)
        end
      end

      it 'regenerates derivatives' do
        expect(updated_asset.derivatives.count).to be 2
        expect(updated_asset.derivatives.map(&:generated_at)).to all(be_within(1.second).of(DateTime.current))
      end
    end
  end
end
