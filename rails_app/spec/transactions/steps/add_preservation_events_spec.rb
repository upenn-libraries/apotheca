# frozen_string_literal: true

describe Steps::AddPreservationEvents do
  describe '#call' do
    let(:asset) { persist(:asset_resource, :with_preservation_file) }
    let(:change_set) do
      change_set = AssetChangeSet.new(asset)
      change_set.validate(update_attributes)
      change_set
    end
    let(:preservation_events) do
      result = described_class.new.call(change_set)
      result.value!.preservation_events
    end

    context 'with preceding events' do
      let(:update_attributes) { { temporary_events: preceding_event } }
      let(:preceding_event) do
        build(:preservation_event, :virus_check, :success,
              outcome_detail_note: I18n.t('preservation_events.virus_check.note'))
      end

      it 'sets any preceding events on the change set' do
        expect(preservation_events).to include preceding_event
      end
    end

    context 'with migration attribute on the change set' do
      let(:update_attributes) do
        {
          preservation_file_id: Valkyrie::ID.new('new-bogus-file-id'),
          migrated_from: 'Internet Archive',
          migrated_filename: 'filename-in-old-system.tif'
        }
      end

      it 'sets a ingest event with migration-specific outcome_detail_note' do
        ingest_event = find_event_by_type events: preservation_events, type: Premis::Events::INGEST
        expect(ingest_event.outcome_detail_note).to eq I18n.t('preservation_events.action.migration_note',
                                                              from: update_attributes[:migrated_from])
      end

      it 'sets the correct messages for the preservation filename change event' do
        filename_event = find_event_by_type events: preservation_events, type: Premis::Events::FILENAME_CHANGE
        expect(filename_event.outcome_detail_note).to include(
          I18n.t('preservation_events.preservation_filename.note', from: update_attributes[:migrated_filename],
                                                                   to: update_attributes[:preservation_file_id])
        )
      end
    end

    context 'with a newly ingested Asset' do
      let(:asset) { build(:asset_resource, original_filename: nil) } # use build instead of persist to denote newness
      let(:update_attributes) do
        { preservation_file_id: Valkyrie::ID.new('bogus-file-id'),
          original_filename: 'bogus-file.tif', technical_metadata: { sha256: 'bogus-sha' } }
      end
      let(:preservation_file_events) do
        find_events_by_type(events: preservation_events, type: Premis::Events::FILENAME_CHANGE)
      end

      it 'sets an ingest event with ingestion-specific outcome_detail_note' do
        ingest_event = find_event_by_type events: preservation_events, type: Premis::Events::INGEST
        expect(ingest_event.outcome_detail_note).to eq I18n.t('preservation_events.action.ingestion_note',
                                                              filename: update_attributes[:original_filename])
      end

      it 'sets an checksum event' do
        event = find_event_by_type events: preservation_events, type: Premis::Events::CHECKSUM
        expect(event.outcome_detail_note).to eq I18n.t('preservation_events.checksum.note',
                                                       checksum: update_attributes[:technical_metadata][:sha256])
      end

      it 'sets two filename change events' do
        expect(preservation_file_events.length).to eq 2
      end

      it 'sets the correct messages for the original_filename change event' do
        expect(preservation_file_events.collect(&:outcome_detail_note)).to include(
          I18n.t('preservation_events.preservation_filename.note',
                 from: update_attributes[:original_filename], to: update_attributes[:preservation_file_id])
        )
      end

      it 'sets the correct messages for the preservation filename change event' do
        expect(preservation_file_events.collect(&:outcome_detail_note)).to include(
          I18n.t('preservation_events.original_filename.note',
                 from: I18n.t('preservation_events.original_filename.nil_placeholder'),
                 to: update_attributes[:original_filename])
        )
      end
    end

    context 'with an Asset receiving a new file via an update with the same filename' do
      let(:update_attributes) do
        { preservation_file_id: Valkyrie::ID.new('new-bogus-file-id'),
          original_filename: asset.original_filename }
      end
      let(:preservation_file_events) do
        find_events_by_type(events: preservation_events, type: Premis::Events::FILENAME_CHANGE)
      end

      it 'sets an ingest event with reingestion-specific outcome_detail_note' do
        ingest_event = find_event_by_type events: preservation_events, type: Premis::Events::INGEST
        expect(ingest_event.outcome_detail_note).to eq I18n.t('preservation_events.action.reingestion_note',
                                                              filename: update_attributes[:original_filename])
      end

      it 'sets a single filename change event' do
        expect(preservation_file_events.length).to eq 1
      end

      it 'sets the correct message for the filename change event' do
        old_file_id = asset.preservation_file_id.id.split('://').last
        expect(preservation_file_events.first.outcome_detail_note).to eq(
          I18n.t('preservation_events.preservation_filename.note', from: old_file_id,
                                                                   to: update_attributes[:preservation_file_id])
        )
      end
    end

    context 'with an Asset receiving a new file via an update with a new filename' do
      let(:update_attributes) do
        { preservation_file_id: Valkyrie::ID.new('new-bogus-file-id'),
          original_filename: 'new-bogus-file.tif' }
      end
      let(:filename_change_events) do
        find_events_by_type(events: preservation_events, type: Premis::Events::FILENAME_CHANGE)
      end

      it 'sets two filename change events' do
        expect(filename_change_events.length).to eq 2
      end

      it 'sets the correct messages for filename change events' do
        messages = filename_change_events.collect(&:outcome_detail_note)
        expect(messages).to include I18n.t('preservation_events.original_filename.note',
                                           from: asset.original_filename,
                                           to: update_attributes[:original_filename])
      end
    end

    context 'when an Asset replicating the preservation file' do
      let(:update_attributes) do
        { preservation_copies_ids: [Valkyrie::ID.new('new-bogus-replicated-file-id')] }
      end

      it 'sets one preservation event' do
        expect(preservation_events.length).to eq 1
      end

      it 'sets a replication event  outcome_detail_note' do
        event = find_event_by_type events: preservation_events, type: Premis::Events::REPLICATION
        expect(event.outcome_detail_note).to eq I18n.t('preservation_events.replication.note',
                                                       filename: update_attributes[:preservation_copies_ids].first)
      end
    end

    context 'with an Asset receiving only updated metadata' do
      let(:update_attributes) { { label: 'Updated Label' } }

      it 'does not set an ingestion event' do
        expect(find_event_by_type(events: preservation_events, type: Premis::Events::INGEST)).to be_nil
      end

      it 'does not set an preservation file event' do
        expect(find_event_by_type(events: preservation_events, type: Premis::Events::FILENAME_CHANGE)).to be_nil
      end
    end

    # return first matching event type
    def find_event_by_type(events:, type:)
      events.find do |event|
        event.event_type.to_s == type.uri
      end
    end

    # return all matching event types
    def find_events_by_type(events:, type:)
      events.select do |event|
        event.event_type.to_s == type.uri
      end
    end
  end
end
