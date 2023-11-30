# frozen_string_literal: true

describe CreateAsset do
  describe '#call' do
    let(:transaction) { described_class.new }
    let(:asset) { result.value! }

    context 'when all required attributes present' do
      let(:result) do
        transaction.call(label: 'Front', created_by: 'initiator@example.com')
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'creates a new Asset resource' do
        expect(asset).to be_a AssetResource
      end

      it 'sets attributes' do
        expect(asset.label).to eql 'Front'
      end

      it 'sets updated_by' do
        expect(asset.updated_by).to eql 'initiator@example.com'
      end

      it 'does not add preservation event' do
        expect(asset.preservation_events.count).to be 0
      end

      it 'records event' do
        event = ResourceEvent.where(resource_identifier: asset.id.to_s, event_type: :create_asset).first
        expect(event).to be_present
        expect(event).to have_attributes(resource_json: a_value, initiated_by: 'initiator@example.com',
                                         completed_at: be_a(Time))
      end
    end

    context 'when creating an asset with an original_filename' do
      let(:result) do
        transaction.call(original_filename: original_filename, label: 'Front', created_by: 'admin@example.com')
      end
      let(:original_filename) { 'front.tif' }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'creates new Asset resource' do
        expect(asset).to be_a AssetResource
      end

      it 'sets original_filename' do
        expect(asset.original_filename).to eql original_filename
      end

      it 'adds preservation event' do
        expect(asset.preservation_events.count).to be 1
        expect(asset.preservation_events.first.event_type.to_s).to eql Premis::Events::FILENAME_CHANGE.uri
      end
    end
  end
end
