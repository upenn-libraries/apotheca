# frozen_string_literal: true

describe Steps::CreateChangeSet do
  let(:resource_class) { AssetResource }
  let(:change_set_class) { AssetChangeSet }

  describe '#call' do
    let(:create_change_set) { described_class.new(resource_class, change_set_class) }

    context 'when attributes valid' do
      subject(:result) { create_change_set.call(original_filename: 'file.txt') }

      it 'returns successful result' do
        expect(result.success?).to be true
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
  end
end
