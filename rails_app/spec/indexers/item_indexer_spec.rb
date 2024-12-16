# frozen_string_literal: true

RSpec.describe ItemIndexer do
  subject(:indexer) { described_class.new(resource: resource) }

  let(:result) { indexer.to_solr }

  context 'when resource is unpublished' do
    let(:resource) { persist(:item_resource) }

    it 'has indexed date_created' do
      expect(result[:date_created_dtsi]).to eql resource.created_at.to_fs(:solr)
    end

    it 'does not have indexed first_published_at' do
      expect(result[:first_published_at_dtsi]).to be_nil
    end

    it 'does not have indexed last_published_at' do
      expect(result[:last_published_at_dtsi]).to be_nil
    end

    it 'has indexed published value' do
      expect(result[:published_bsi]).to be false
    end
  end

  context 'when resource is published' do
    let(:resource) { persist(:item_resource, :published) }

    it 'has indexed first_published_at' do
      expect(result[:first_published_at_dtsi]).to eql resource.first_published_at.to_fs(:solr)
    end

    it 'had indexed last_published_at' do
      expect(result[:last_published_at_dtsi]).to eql resource.last_published_at.to_fs(:solr)
    end

    it 'has indexed published value' do
      expect(result[:published_bsi]).to be true
    end
  end

  context 'when resource has been migrated' do
    let(:resource) { persist(:item_resource, :migrated) }

    it 'has expected date_created value' do
      expect(result[:date_created_dtsi]).to eql resource.first_created_at.to_fs(:solr)
    end
  end
end
