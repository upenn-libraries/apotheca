# frozen_string_literal: true

describe Resource::Steps::CreateChangeSet do
  let(:resource_class) { AssetResource }
  let(:change_set_class) { AssetChangeSet }

  describe '#call' do
    let(:create_change_set) { described_class.new(resource_class, change_set_class) }

    context 'when attributes valid' do
      subject(:result) { create_change_set.call(original_filename: 'file.txt') }

      it 'returns successful result' do
        expect(result.success?).to be true
      end

      it 'returns a change set' do
        expect(result.value!).to be_a AssetChangeSet
      end
    end

    context 'when attributes invalid' do
      subject(:result) { create_change_set.call(original_filename: 'file.txt', technical_metadata: 'invalid') }

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns expected failure' do
        expect(result.failure[:error]).to be :error_creating_change_set
        expect(result.failure[:exception]).to be_an Exception
      end
    end

    context 'when resource present' do
      subject(:result) { create_change_set.call(resource: asset, original_filename: 'file.txt') }

      let(:asset) { persist(:asset_resource) }

      it 'returns successful result' do
        expect(result.success?).to be true
      end

      it 'uses resource provided' do
        expect(result.value!.resource).to eq asset
      end
    end
  end
end
