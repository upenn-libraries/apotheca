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

    it 'returns expected title' do
      first_title = report['items'].first['descriptive_metadata']['title'].first['value']
      last_title = report['items'].last['descriptive_metadata']['title'].first['value']
      expect(first_title).to eq(items.first.descriptive_metadata.title.first.value)
      expect(last_title).to eq(items.last.descriptive_metadata.title.first.value)
    end

    it 'returns expected collection' do
      first_collection = report['items'].first['descriptive_metadata']['collection'].first['value']
      last_collection = report['items'].last['descriptive_metadata']['collection'].first['value']
      expect(first_collection).to eq(items.first.descriptive_metadata.collection.first.value)
      expect(last_collection).to eq(items.last.descriptive_metadata.collection.first.value)
    end

    it 'returns expected item_type value' do
      first_item_type = report['items'].first['descriptive_metadata']['item_type'].first['value']
      last_item_type = report['items'].last['descriptive_metadata']['item_type'].first['value']
      expect(first_item_type).to eq(items.first.descriptive_metadata.item_type.first.value)
      expect(last_item_type).to eq(items.last.descriptive_metadata.item_type.first.value)
    end

    it 'returns expected URIs' do
      first_uri = report['items'].first['descriptive_metadata']['item_type'].first['uri']
      last_uri = report['items'].last['descriptive_metadata']['item_type'].first['uri']
      expect(first_uri).to eq(items.first.descriptive_metadata.item_type.first.uri)
      expect(last_uri).to eq(items.last.descriptive_metadata.item_type.first.uri)
    end

    it 'returns expect physical_format' do
      first_physical_format = report['items'].first['descriptive_metadata']['physical_format'].first['value']
      last_physical_format = report['items'].last['descriptive_metadata']['physical_format'].first['value']
      expect(first_physical_format).to eq(items.first.descriptive_metadata.physical_format.first.value)
      expect(last_physical_format).to eq(items.last.descriptive_metadata.physical_format.first.value)
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

    it 'returns expected asset filename' do
      expect(report['items'].first['assets'].first['filename']).to eq asset.original_filename
      expect(report['items'].last['assets'].first['filename']).to eq asset.original_filename
    end

    it 'returns expected asset mime_type' do
      expect(report['items'].first['assets'].first['mime_type']).to eq asset.technical_metadata.mime_type
      expect(report['items'].last['assets'].first['mime_type']).to eq asset.technical_metadata.mime_type
    end

    it 'returns expected asset size' do
      expect(report['items'].first['assets'].first['size']).to eq asset.technical_metadata.size
      expect(report['items'].last['assets'].first['size']).to eq asset.technical_metadata.size
    end

    it 'returns asset created_at' do
      expect(report['items'].first['assets'].first['created_at']).to eq asset.created_at.iso8601
      expect(report['items'].last['assets'].first['created_at']).to eq asset.created_at.iso8601
    end

    it 'returns asset updated_at' do
      expect(report['items'].first['assets'].first['updated_at']).to eq asset.updated_at.iso8601
      expect(report['items'].last['assets'].first['updated_at']).to eq asset.updated_at.iso8601
    end
  end
end
