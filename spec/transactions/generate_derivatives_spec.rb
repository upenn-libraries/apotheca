# frozen_string_literal: true

describe GenerateDerivatives do
  describe '#call' do
    subject(:updated_asset) { result.value! }

    let(:transaction) { described_class.new }
    let(:asset) { persist(:asset_resource, :with_preservation_file) }
    let(:result) { transaction.call(id: asset.id) }

    context 'when derivatives not present' do
      it 'generates and adds derivatives' do
        expect(updated_asset.derivatives.length).to be 2
        expect(updated_asset.derivatives.map(&:type)).to contain_exactly 'thumbnail', 'access'
      end
    end

    context 'when derivatives already present' do
      it 'regenerates derivatives' # check timestamps
    end
  end
end
