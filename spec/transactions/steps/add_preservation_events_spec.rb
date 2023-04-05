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
      let(:asset) { persist(:asset_resource, :with_preservation_file) }
      let(:change_set) { AssetChangeSet.new(asset, migrated_object: true) }
      let(:result) { described_class.new.call(change_set) }

      it 'sets a ingest event with migration-specific outcome_detail_note' do
        ingest_event = result.value!.preservation_events.find { |ev| ev.event_type.to_s == Premis::Events::INGEST.uri }
        expect(ingest_event.outcome_detail_note).to eq 'Object migrated from Bulwark to Apotheca'
      end
    end

    context 'with a newly ingested Asset' do
      let(:asset) { build(:asset_resource, :with_preservation_file) } # TODO: file needed here only for setting of checksum in tech md
      let(:change_set) { AssetChangeSet.new(asset, preservation_file_id: 'bogus-file-id', original_filename: 'bogus-file.jpg') } # TODO: is this ok?
      let(:result) { described_class.new.call(change_set) }

      it 'sets an ingest event with ingestion-specific outcome_detail_note' do
        ingest_event = result.value!.preservation_events.find { |ev| ev.event_type.to_s == Premis::Events::INGEST.uri }
        expect(ingest_event.outcome_detail_note).to eq "Object ingested as #{change_set.original_filename}"
      end
    end

    context 'with an Asset receiving a new file via an update' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) } # TODO: file needed here only for setting of checksum in tech md
      let(:change_set) { AssetChangeSet.new(asset, preservation_file_id: 'new-bogus-file-id', original_filename: 'new-bogus-file.jpg') } # TODO: is this ok?
      let(:result) { described_class.new.call(change_set) }

      it 'sets an ingest event with reingestion-specific outcome_detail_note' do
        ingest_event = result.value!.preservation_events.find { |ev| ev.event_type.to_s == Premis::Events::INGEST.uri }
        expect(ingest_event.outcome_detail_note).to eq "New file ingested as #{change_set.original_filename}"
      end
    end

    context 'for an Asset receiving only updated metadata' do
      let(:asset) { persist(:asset_resource, :with_preservation_file) } # TODO: file needed here only for setting of checksum in tech md
      let(:change_set) { AssetChangeSet.new(asset) }
      let(:result) { described_class.new.call(change_set) }

      it 'does not set an ingestion event' do
        ingest_event = result.value!.preservation_events.find { |ev| ev.event_type.to_s == Premis::Events::INGEST.uri }
        expect(ingest_event).to be_nil
      end
    end
  end
end
