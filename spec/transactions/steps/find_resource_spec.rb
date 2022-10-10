# frozen_string_literal: true

describe Steps::FindResource do
  let(:resource_class) { AssetResource }

  describe '#call' do
    let(:find_resource) { described_class.new(resource_class) }

    context 'when :id is not valid' do
      subject(:result) { find_resource.call(id: 'not-valid') }

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns errors' do
        expect(result.failure.first).to be :resource_not_found
        expect(result.failure.second).to be_a Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when id is not valid for resource' do
      subject(:result) { find_resource.call(id: item.id) }

      let(:item) { persist(:item_resource) }

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns errors' do
        expect(result.failure.first).to be :resource_not_found
        expect(result.failure.second).to be_a Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end