# frozen_string_literal: true

describe DerivativeService::Item::ManifestGenerator::V2::MetadataBuilder do
  describe '#build' do
    subject(:metadata) { described_class.new(item.presenter).build }

    let(:item) do
      persist(
        :item_resource, :with_full_assets_all_arranged,
        descriptive_metadata: {
          title: [{ value: 'New Item' }],
          name: [{ value: 'Random, Person', role: [{ value: 'Illustrator' }, { value: 'Creator' }] }],
          rights: [{ value: 'In Copyright', uri: 'http://rightsstatements.org/vocab/InC/1.0/' }],
          rights_note: [{ value: 'Contact copyright owner' }]
        }
      )
    end

    it 'includes availability information at the top' do
      expect(metadata[0]).to include(label: 'Available Online',
                                     value: [starting_with('https://digitalcollections.library.upenn.edu/items/')])
    end

    it 'includes descriptive metadata' do
      expect(metadata).to include(
        { label: 'Title', value: ['New Item'] },
        { label: 'Name', value: ['Random, Person (Illustrator, Creator)'] },
        { label: 'Rights', value: ['http://rightsstatements.org/vocab/InC/1.0/'] },
        { label: 'Rights Note', value: ['Contact copyright owner'] }
      )
    end
  end
end
