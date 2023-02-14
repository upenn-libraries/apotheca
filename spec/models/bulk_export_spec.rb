# frozen_string_literal: true

require_relative 'concerns/queueable'

describe BulkExport do
  it_behaves_like 'queueable'

  it 'requires a user' do
    bulk_export = build :bulk_export, user: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['user']).to include 'must exist'
  end

  it 'requires solr params' do
    bulk_export = build :bulk_export, solr_params: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['solr_params']).to include "can't be blank"
  end

  it 'requires state to be set' do
    bulk_export = build :bulk_export, state: nil
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['state']).to include "can't be blank"
  end

  it 'requires generated_by if csv is attached' do
    bulk_export = build :bulk_export
    bulk_export.csv.attach(io: StringIO.new('contents'), filename: 'file.csv')
    expect(bulk_export.valid?).to be false
    expect(bulk_export.errors['generated_at']).to include "can't be blank"
  end

  describe '#csv' do
    let(:bulk_export) { create :bulk_export, generated_at: DateTime.current }

    it 'attaches a csv file' do
      bulk_export.csv.attach(io: StringIO.new('contents'), filename: 'file.csv')
      expect(bulk_export.csv).to be_attached
      expect(bulk_export.csv.download).to eq 'contents'
    end
  end

  describe '#sanitized_filename' do
    before { persist(:item_resource) }

    context 'when there is no title' do
      let(:bulk_export) { create(:bulk_export, :processing) }

      before { bulk_export.run }

      it 'generates the correct filename' do
        expect(bulk_export.csv.filename.to_s).to eq("#{bulk_export.generated_at.strftime('%Y%m%d_%H%M%S')}.csv")
      end
    end

    context 'when title does not contain dangerous characters' do
      let(:bulk_export) { create(:bulk_export, :processing, title: 'Crunchy') }

      before { bulk_export.run }

      it 'generates the correct filename' do
        expect(bulk_export.csv.filename.to_s)
          .to eq("#{bulk_export.title}_#{bulk_export.generated_at.strftime('%Y%m%d_%H%M%S')}.csv")
      end
    end

    context 'when title contains dangerous characters' do
      let(:safe_chars)  { 'Crunchy' }
      let(:dangerous_chars) { ':$/' }
      let(:title) { dangerous_chars + safe_chars }
      let(:bulk_export) { create(:bulk_export, :processing, title: title) }

      before { bulk_export.run }

      it 'includes the safe characters in the filename' do
        expect(bulk_export.csv.filename.to_s).to include(safe_chars)
      end

      it 'removes dangerous characters from filename' do
        expect(bulk_export.title).to include(dangerous_chars)
        expect(bulk_export.csv.filename.to_s).not_to include(dangerous_chars)
      end

      it 'generates the correct filename' do
        expect(bulk_export.csv.filename.to_s)
          .to eq("---#{safe_chars}_#{bulk_export.generated_at.strftime('%Y%m%d_%H%M%S')}.csv")
      end
    end
  end

  describe '#process!' do
    let(:bulk_export) { create :bulk_export, :queued }

    it 'calls #run' do
      allow(bulk_export).to receive(:run).and_call_original
      bulk_export.process!
      expect(bulk_export).to have_received(:run)
    end
  end

  describe '#run' do
    let!(:item1) do
      persist(:item_resource, descriptive_metadata: { title: 'The New Catcher In The Rye' },
                              human_readable_name: 'Item')
    end
    let!(:item2) { persist(:item_resource) }

    context 'when processing' do
      let(:bulk_export) { create(:bulk_export, :processing, include_assets: true) }

      before do
        allow(bulk_export).to receive(:bulk_export_csv)
        allow(bulk_export).to receive(:sanitized_filename)
        bulk_export.run
      end

      it 'passes include_assets to the export method' do
        expect(bulk_export).to have_received(:bulk_export_csv)
          .with(hash_including(include_assets: bulk_export.include_assets))
      end

      it 'calls sanitized filename' do
        expect(bulk_export).to have_received(:sanitized_filename)
      end

    end

    context 'when successful and contains two search results' do
      let(:bulk_export) { create(:bulk_export, :processing) }

      before { bulk_export.run }

      it 'changes state to successful' do
        expect(bulk_export.state).to eq described_class::STATE_SUCCESSFUL.to_s
      end

      it 'calculates and stores duration' do
        expect(bulk_export.duration).not_to be_nil
      end

      it 'sets generated_at' do
        expect(bulk_export.generated_at).not_to be_nil
      end

      it 'attaches csv to record' do
        expect(bulk_export.csv).to be_attached
      end

      it 'generates csv with correct data' do
        expect(bulk_export.csv.download).to include(item1.descriptive_metadata.title.first)
        expect(bulk_export.csv.download).to include(item2.descriptive_metadata.title.first)
      end

      it 'generates csv with the correct filename' do
        expect(bulk_export.csv.filename.to_s).to eq("#{bulk_export.generated_at.strftime('%Y%m%d_%H%M%S')}.csv")
      end
    end

    context 'when successful and contains one search results' do
      let(:bulk_export) { create(:bulk_export, :processing, solr_params: { search: { all: 'Catcher' } }) }

      before { bulk_export.run }

      it 'changes state to successful' do
        expect(bulk_export.state).to eq described_class::STATE_SUCCESSFUL.to_s
      end

      it 'generates csv data for one search result' do
        expect(bulk_export.csv.download).to include(item1.descriptive_metadata.title.first)
        expect(bulk_export.csv.download).not_to include(item2.descriptive_metadata.title.first)
      end
    end

    context 'when solr_params return no search results' do
      let(:bulk_export) { create(:bulk_export, :processing, solr_params: { search: { all: 'Basketball' } }) }

      before { bulk_export.run }

      it 'changes state to failed' do
        expect(bulk_export.state).to eq described_class::STATE_FAILED.to_s
      end

      it 'does not attach csv' do
        expect(bulk_export.csv).not_to be_attached
      end

      it 'updates process_errors attribute' do
        expect(bulk_export.process_errors.first).to eq('No search results returned, cannot generate csv')
      end
    end

    context 'when an error is raised' do
      let(:bulk_export) { create(:bulk_export, :processing) }

      before do
        allow(bulk_export).to receive(:bulk_export_csv).and_raise(StandardError.new('test error'))
        bulk_export.run
      end

      it 'changes state to failed' do
        expect(bulk_export.state).to eq BulkExport::STATE_FAILED.to_s
      end

      it 'updates the process_errors attribute' do
        expect(bulk_export.process_errors.first).to eq('test error')
      end
    end
  end

  context 'with associated User validation' do
    let(:user) { create :user, :admin }

    before { create_list(:bulk_export, 10, user: user) }

    it 'does not allow more than 10 bulk exports' do
      bulk_export = build(:bulk_export, user: user)
      expect(bulk_export).to be_invalid
      expect(bulk_export.errors[:user]).to include('The number of Bulk Exports for a user cannot exceed 10.')
    end
  end
end