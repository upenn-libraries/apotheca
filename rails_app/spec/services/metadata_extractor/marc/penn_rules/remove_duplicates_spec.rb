# frozen_string_literal: true

RSpec.describe MetadataExtractor::MARC::PennRules::RemoveDuplicates do
  let(:cleanup) { described_class.new(fields: []) }

  describe '#apply' do
    context 'when removing duplicate names' do
      let(:creator) { { value: 'Random, Person', role: [{ value: 'creator' }] } }
      let(:creator_with_uri) { { value: 'Random, Person', uri: 'https://example.com/random-person', role: [{ value: 'creator' }] } }
      let(:illustrator) { { value: 'Random, Person', role: [{ value: 'illustrator' }] } }

      it 'removes duplicate values that have the same role' do
        values = [creator, creator_with_uri]
        expect(cleanup.apply(values)).to contain_exactly(creator_with_uri)
      end

      it 'does not remove duplicate values that have different roles' do
        values = [creator, creator_with_uri, illustrator]
        expect(cleanup.apply(values)).to contain_exactly(creator_with_uri, illustrator)
      end
    end

    context 'when removing duplicates with URIs' do
      let(:with_loc_uri) { { value: 'World history', uri: 'http://id.loc.gov/authorities/subjects/sh85148201' } }
      let(:with_fast_uri) { { value: 'World history', uri: 'http://id.worldcat.org/fast/1181345' } }
      let(:with_upenn_uri) { { value: 'World history', uri: 'http://id.library.upenn.edu/world-history' } }
      let(:without_uri) { { value: 'World history' } }

      it 'prefers LOC URIs over other authorities' do
        values = [with_loc_uri, with_fast_uri, without_uri]
        expect(cleanup.apply(values)).to contain_exactly(with_loc_uri)
      end

      it 'prefers values with URI over values without URIs' do
        values = [with_fast_uri, with_upenn_uri, without_uri]
        expect(cleanup.apply(values)).to contain_exactly(with_fast_uri, with_upenn_uri)
      end

      it 'removes duplicate' do
        values = [without_uri, without_uri]
        expect(cleanup.apply(values)).to contain_exactly(without_uri)
      end
    end
  end
end
