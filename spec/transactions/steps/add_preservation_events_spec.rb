# frozen_string_literal: true

describe Steps::AddPreservationEvents do
  describe '#call' do
    context 'with preceding events' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:change_set) { AssetChangeSet.new(asset, temporary_events: preceding_event) }
      let(:preceding_event) do
        build(:preservation_event, :virus_check, :success, :user_agent, outcome_detail_note: 'No virus')
      end
      let(:result) { described_class.new.call(change_set) }

      it 'sets any preceding events on the change set' do
        expect(result.value!.preservation_events).to include preceding_event
      end
    end

    context 'with migration attribute on the change set' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:change_set) { AssetChangeSet.new(asset, migrated_from: 'Internet Archive') }
      let(:result) { described_class.new.call(change_set) }

      it 'sets a ingest event with migration-specific outcome_detail_note' do
        ingest_event = find_event_type events: result.value!.preservation_events, type: Premis::Events::INGEST.uri
        expect(ingest_event.outcome_detail_note).to eq 'Object migrated from Internet Archive to Apotheca'
      end
    end

    context 'with a newly ingested Asset' do
      let(:asset) { build(:asset_resource, :with_preservation_file) }
      let(:change_set) do
        AssetChangeSet.new(asset,
                           preservation_file_id: Valkyrie::ID.new('bogus-file-id'),
                           original_filename: 'bogus-file.jpg')
      end
      let(:result) { described_class.new.call(change_set) }
      let(:filename_events) do
        result.value!.preservation_events.select { |ev| ev.event_type.to_s == Premis::Events::EDIT_FILENAME.uri }
      end

      it 'sets an ingest event with ingestion-specific outcome_detail_note' do
        ingest_event = find_event_type events: result.value!.preservation_events, type: Premis::Events::INGEST.uri
        expect(ingest_event.outcome_detail_note).to eq "Object ingested as #{change_set.original_filename}"
      end

      it 'sets a single filename change event' do
        expect(filename_events.length).to eq 1
      end

      it 'sets the correct message for the filename change event' do
        expect(filename_events.first.outcome_detail_note).to eq(
          "File's original filename renamed from #{change_set.original_filename} to #{change_set.preservation_file_id}"
        )
      end
    end

    context 'with an Asset receiving a new file via an update' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:change_set) do
        AssetChangeSet.new(asset,
                           preservation_file_id: Valkyrie::ID.new('new-bogus-file-id'),
                           original_filename: 'new-bogus-file.jpg')
      end
      let(:result) { described_class.new.call(change_set) }
      let(:filename_events) do
        result.value!.preservation_events.select { |ev| ev.event_type.to_s == Premis::Events::EDIT_FILENAME.uri }
      end

      it 'sets an ingest event with reingestion-specific outcome_detail_note' do
        ingest_event = find_event_type events: result.value!.preservation_events, type: Premis::Events::INGEST.uri
        expect(ingest_event.outcome_detail_note).to eq "New file ingested as #{change_set.original_filename}"
      end

      it 'sets a single filename change event' do
        expect(filename_events.length).to eq 1
      end

      it 'sets the correct message for the filename change event' do
        old_file_id = change_set.resource.preservation_file_id.id.split('/').last
        expect(filename_events.first.outcome_detail_note).to eq(
          "File's original filename renamed from #{old_file_id} to #{change_set.preservation_file_id}"
        )
      end
    end

    context 'with an Asset receiving only updated metadata' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:change_set) { AssetChangeSet.new(asset) }
      let(:result) { described_class.new.call(change_set) }

      it 'does not set an ingestion event' do
        expect(
          find_event_type(events: result.value!.preservation_events, type: Premis::Events::INGEST.uri)
        ).to be_nil
      end

      it 'does not set an filename event' do
        expect(
          find_event_type(events: result.value!.preservation_events, type: Premis::Events::EDIT_FILENAME.uri)
        ).to be_nil
      end
    end

    # return first matching event type
    def find_event_type(events:, type:)
      events.find do |event|
        event.event_type.to_s == type
      end
    end
  end
end
