# frozen_string_literal: true

describe CreateAsset do
  describe '#call' do
    let(:transaction) { described_class.new }

    context 'when all required attributes present' do
      subject(:asset) { result.value! }

      let(:result) do
        transaction.call(
          original_filename: 'front.jpeg',
          label: 'Front',
          created_by: 'admin@example.com'
        )
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'creates a new Asset Resource' do
        expect(asset).to be_a AssetResource
      end

      it 'sets attributes' do
        expect(asset.original_filename).to eql 'front.jpeg'
        expect(asset.label).to eql 'Front'
      end

      it 'sets updated_by' do
        expect(asset.updated_by).to eql 'admin@example.com'
      end
    end
  end
end
