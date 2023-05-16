# frozen_string_literal: true

describe Steps::AddPreservationEvents do
  describe '#call' do
    let(:asset) { persist(:asset_resource, :with_preservation_file) }
    let(:result) do
      change_set = AssetChangeSet.new(asset)
      change_set.validate(update_attributes)
      described_class.new.call(change_set)
    end
    let(:preservation_events) { result.value!.preservation_events }

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
      let(:update_attributes) { { migrated_from: 'Internet Archive' } }

      it 'sets a ingest event with migration-specific outcome_detail_note' do
        ingest_event = find_event_by_type events: preservation_events, type: Premis::Events::INGEST
        expect(ingest_event.outcome_detail_note).to eq I18n.t('preservation_events.action.migration_note',
                                                              from: update_attributes[:migrated_from])
      end
    end

    context 'with a newly ingested Asset' do
      let(:asset) { build(:asset_resource, :with_preservation_file) } # use build instead of persist to denote newness
      let(:update_attributes) do
        { preservation_file_id: Valkyrie::ID.new('bogus-file-id'),
          original_filename: 'bogus-file.jpg' }
      end
      let(:preservation_file_events) do
        find_events_by_type(events: preservation_events, type: Premis::Events::FILENAME_CHANGE)
      end

      it 'sets an ingest event with ingestion-specific outcome_detail_note' do
        ingest_event = find_event_by_type events: preservation_events, type: Premis::Events::INGEST
        expect(ingest_event.outcome_detail_note).to eq I18n.t('preservation_events.action.ingestion_note',
                                                              filename: update_attributes[:original_filename])
      end

      it 'sets a single filename change event' do
        expect(preservation_file_events.length).to eq 1
      end

      it 'sets the correct message for the filename change event' do
        expect(preservation_file_events.first.outcome_detail_note).to eq(
          I18n.t('preservation_events.preservation_filename.note',
                 from: update_attributes[:original_filename], to: update_attributes[:preservation_file_id])
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
        old_file_id = asset.preservation_file_id.id.split('/').last
        expect(preservation_file_events.first.outcome_detail_note).to eq(
          I18n.t('preservation_events.preservation_filename.note', from: old_file_id,
                                                                   to: update_attributes[:preservation_file_id])
        )
      end
    end

    context 'with an Asset receiving a new file via an update with a new filename' do
      let(:update_attributes) do
        { preservation_file_id: Valkyrie::ID.new('new-bogus-file-id'),
          original_filename: 'new-bogus-file.jpg' }
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
