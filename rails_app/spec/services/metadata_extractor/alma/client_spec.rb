# frozen_string_literal: true

describe MetadataExtractor::Alma::Client do
  describe '.new' do
    subject(:alma) { described_class.new }

    it { is_expected.to be_a described_class }
  end

  describe '#marc_xml' do
    let(:alma) { described_class.new }
    let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

    context 'when request is successful' do
      include_context 'with successful Alma request' do
        let(:xml) { File.read(file_fixture('alma/marc_xml/book-1.xml')) }
      end

      it 'returns expected MARC XML' do
        expect(alma.marc_xml(bibnumber)).to eql xml
      end
    end

    context 'when request is unsuccessful' do
      include_context 'with unsuccessful Alma request'

      let(:alma_error) { 'Request failed: Alma API error' }

      it 'raises exception' do
        expect {
          alma.marc_xml(bibnumber)
        }.to raise_error(MetadataExtractor::Alma::Client::Error,
                         'Alma API error: 401652 General Error - An error has occurred')
      end
    end
  end
end
