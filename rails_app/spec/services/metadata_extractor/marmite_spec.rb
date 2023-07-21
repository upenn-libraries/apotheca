# frozen_string_literal: true

describe MetadataExtractor::Marmite do
  let(:url) { Settings.marmite.url }

  describe '.new' do
    subject(:marmite) { described_class.new(url: url) }

    it { is_expected.to be_a described_class }

    it 'sets url' do
      expect(marmite.client.url).to eql url
    end
  end

  describe '#descriptive_metadata' do
    subject(:metadata) { marmite.descriptive_metadata(bibnumber) }

    let(:marmite) { described_class.new(url: url) }
    let(:bibnumber) { 'sample-bib' }
    let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }

    context 'when record is found' do
      before do
        stub_request(:get, "#{Settings.marmite.url}/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 200, body: marc_xml, headers: {})
      end

      it 'returns descriptive metadata' do
        expect(metadata).to be_a Hash
        expect(metadata[:item_type].pluck(:value)).to eql ['Text']
      end
    end

    context 'when record is not found' do
      let(:errors) { ["Bib not found in Alma for #{bibnumber}"] }

      before do
        stub_request(:get, "#{Settings.marmite.url}/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 404, body: JSON.generate({ errors: errors }), headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises an error with the correct message' do
        expect { metadata }.to raise_error(MetadataExtractor::Marmite::Client::Error) do |error|
          expect(error.message).to include(errors.join(' '))
        end
      end
    end
  end
end
