# frozen_string_literal: true

describe MetadataExtractor::Marmite do
  let(:url) { Settings.marmite.url }

  describe '.new' do
    subject(:marmite) { described_class.new(url: url) }

    it { is_expected.to be_a described_class }

    it 'creates client' do
      expect(marmite.client).to be_a MetadataExtractor::Marmite::Client
    end
  end

  describe '#descriptive_metadata' do
    subject(:metadata) { marmite.descriptive_metadata(bibnumber) }

    let(:marmite) { described_class.new(url: url) }
    let(:bibnumber) { 'sample-bib' }

    context 'when record is found' do
      include_context 'with successful Marmite request' do
        let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
      end

      it 'returns descriptive metadata' do
        expect(metadata).to be_a Hash
        expect(metadata[:item_type].pluck(:value)).to eql ['Text']
      end
    end
  end
end
