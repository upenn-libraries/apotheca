# frozen_string_literal: true

describe MetadataExtractor::Alma do
  describe '.new' do
    subject(:alma) { described_class.new }

    it { is_expected.to be_a described_class }

    it 'creates client' do
      expect(alma.client).to be_a MetadataExtractor::Alma::Client
    end
  end

  describe '#descriptive_metadata' do
    subject(:metadata) { alma.descriptive_metadata(bibnumber) }

    let(:alma) { described_class.new }
    let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

    context 'when record is found' do
      include_context 'with successful Alma request' do
        let(:xml) { File.read(file_fixture('alma/marc_xml/book-1.xml')) }
      end

      it 'returns descriptive metadata' do
        expect(metadata).to be_a Hash
        expect(metadata[:item_type].pluck(:value)).to eql ['Text']
      end
    end
  end
end
