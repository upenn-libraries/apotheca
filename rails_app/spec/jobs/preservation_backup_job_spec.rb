# frozen_string_literal: true

describe PreservationBackupJob do
  let(:asset) { persist(:asset_resource, :with_image_file) }

  it_behaves_like 'OperationJob' do
    let(:args) { [asset.id.to_s, asset.updated_by] }
  end

  describe '#operation' do
    context 'with an invalid asset' do
      let(:result) { described_class.new.operation('non_id', 'test@test.com') }

      it 'returns success' do
        expect(result).to be_a Dry::Monads::Success
      end
    end
  end
end
