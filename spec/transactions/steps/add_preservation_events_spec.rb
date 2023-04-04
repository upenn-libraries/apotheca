# frozen_string_literal: true

describe Steps::AddPreservationEvents do
  describe '#call' do
    context 'with preceding events' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:change_set) { AssetChangeSet.new(asset) }
      let(:preceding_event) { build(:preservation_event, :virus_check, :success, :user_agent, outcome_detail_note: 'No virus') }
      let(:result) { described_class.new.call(change_set, events: preceding_event) }

      it 'sets any preceding events on the change set' do
        expect(result.value!.preservation_events).to include preceding_event
      end
    end

    context 'with migration attribute on the change set' do

    end

    context 'for a newly ingested Asset' do

    end

    context 'for an Asset receiving a new file via an update' do

    end

    context 'for an Asset receiving only updated metadata' do

    end
  end
end
