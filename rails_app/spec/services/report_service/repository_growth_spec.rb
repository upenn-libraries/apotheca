# frozen_string_literal: true

describe ReportService::RepositoryGrowth do
  let(:repository_growth) { described_class.new }
  let(:asset) { persist(:asset_resource, :with_image_file) }
  let(:items) do
    [
      persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id]),
      persist(:item_resource, :with_faker_metadata, asset_ids: [asset.id])
    ]
  end

  before { allow(repository_growth).to receive(:items).and_return(items) }

  describe '#build' do
    let(:report) { JSON.parse(repository_growth.build.read) }

    before { items }

    it 'returns a StringIO' do
      expect(repository_growth.build).to be_a(StringIO)
    end

    it 'returns the expected amount of items' do
      expect(report['items'].size).to eq(items.size)
    end

    it 'returns the expected unique identifier' do
      expect(report['items'].first['unique_identifier']).to eq items.first.unique_identifier
      expect(report['items'].last['unique_identifier']).to eq items.last.unique_identifier
    end

    it 'returns the expected create_date' do
      expect(report['items'].first['create_date']).to eq items.first.date_created.iso8601
      expect(report['items'].last['create_date']).to eq items.last.date_created.iso8601
    end

    it 'returns the system_create_date' do
      expect(report['items'].first['system_create_date']).to eq items.first.created_at.iso8601
      expect(report['items'].last['system_create_date']).to eq items.last.created_at.iso8601
    end

    it 'returns refined descriptive metadata' do
      first_descriptive_metadata = report['items'].first['descriptive_metadata']
      last_descriptive_metadata = report['items'].last['descriptive_metadata']
      fields = described_class::DESCRIPTIVE_METADATA_FIELDS
      expect(first_descriptive_metadata.deep_symbolize_keys.keys).to match_array(fields)
      expect(last_descriptive_metadata.deep_symbolize_keys.keys).to match_array(fields)
    end

    it 'returns an empty array for blank descriptive metadata values' do
      rights = report['items'].first['descriptive_metadata']['rights']
      expect(items.first.descriptive_metadata.rights).to be_blank
      expect(rights).to eq []
    end

    it 'returns expected number of assets' do
      expect(report['items'].first['assets'].size).to eq(items.first.asset_count)
      expect(report['items'].last['assets'].size).to eq(items.last.asset_count)
    end

    it 'returns expected asset data' do
      report['items'].each do |item_hash|
        expect(item_hash['assets'].first).to a_hash_including(
          "filename" => asset.original_filename, "mime_type" => asset.technical_metadata.mime_type, "size" => asset.technical_metadata.size,
        )
      end
    end

    context 'when item has no assets' do
      let(:items) { [persist(:item_resource, :with_faker_metadata)] }

      it 'returns empty asset data' do
        expect(report['items'].first['assets']).to eql []
      end
    end
  end
end
