# frozen_string_literal: true

RSpec.describe DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(resource: resource) }

  let(:result) { indexer.to_solr }

  context 'when an item does not have a bibnumber' do
    let(:metadata) do
      {
        title: [{ value: 'New Item' }],
        name: [
          {
            value: 'Random, Person',
            uri: 'https://example.com/random_person',
            role: [{ value: 'creator', uri: 'https://example.com/creator' }]
          }
        ]
      }
    end

    let(:resource) { persist(:item_resource, descriptive_metadata: metadata) }

    it 'has solr fields for all descriptive metadata fields' do
      ItemResource::DescriptiveMetadata::Fields.all.each do |f|
        expect(result.keys).to include(/#{f}/)
      end
    end

    it 'has indexed title from the Resource' do
      expect(result[:title_tsi]).to eq resource.descriptive_metadata.title.first.value
    end

    it 'has indexed names from the Resource' do
      expect(result[:name_tsim]).to contain_exactly('Random, Person')
      expect(result[:name_with_role_ssm]).to contain_exactly('Random, Person (creator)')
    end

    it 'has indexed roles from the Resource' do
      expect(result[:name_role_tsim]).to contain_exactly('creator')
    end

    it 'has solr fields with JSON representation of source metadata' do
      expect(result[described_class::RESOURCE_METADATA_JSON_FIELD]).to be_present
      expect(result[described_class::ILS_METADATA_JSON_FIELD]).to be_blank
    end
  end

  context 'when an item has a bibnumber' do
    include_context 'with successful Marmite request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    end

    let(:resource) { persist(:item_resource, :with_bibnumber) }
    let(:expected_subjects) do
      ['Metallurgy -- Early works to 1800', 'Assaying -- Early works to 1800', 'Assaying', 'Metallurgy']
    end

    it 'has field values that prefer values from the Resource' do
      expect(result[:collection_tsim]).to contain_exactly resource.descriptive_metadata.collection.first.value
    end

    it 'has values from MARC metadata when Resource fields are blank' do
      expect(result[:name_tsim]).to contain_exactly('Ercker, Lazarus, -1594', 'Feyerabend, Johann, 1550-1599')
      expect(result[:subject_tsim]).to match_array expected_subjects
    end

    it 'has solr fields with JSON representation of source metadata' do
      expect(result[described_class::RESOURCE_METADATA_JSON_FIELD]).to be_present
      expect(result[described_class::ILS_METADATA_JSON_FIELD]).to be_present
    end
  end
end
