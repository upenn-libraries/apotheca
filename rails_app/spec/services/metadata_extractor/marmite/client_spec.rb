# frozen_string_literal: true

describe MetadataExtractor::Marmite::Client do
  let(:url) { Settings.marmite.url }

  describe '.new' do
    subject(:marmite) { described_class.new(url: url) }

    it { is_expected.to be_a described_class }

    it 'sets url' do
      expect(marmite.url).to eql url
    end
  end

  describe '#marc21' do
    let(:marmite) { described_class.new(url: url) }
    let(:bibnumber) { 'sample-bib' }

    context 'when request is successful' do
      include_context 'with successful Marmite request' do
        let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
      end

      it 'returns expected MARC XML' do
        expect(marmite.marc21(bibnumber)).to eql xml
      end
    end

    context 'when request is unsuccessful' do
      let(:marmite_error) { 'Request failed: Alma API error' }

      before do
        stub_request(:get, "#{url}/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 500, body: { errors: [marmite_error] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises exception' do
        expect {
          marmite.marc21(bibnumber)
        }.to raise_error(MetadataExtractor::Marmite::Client::Error,
                         "Could not retrieve MARC for #{bibnumber}. Error: #{marmite_error}")
      end
    end

    context 'when request is unsuccessful with non-JSON response body' do
      let(:raw_marmite_error) { 'Internal Server Error' }

      before do
        stub_request(:get, "#{url}/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 500, body: raw_marmite_error)
      end

      it 'raises exception with raw response included in the message' do
        expect {
          marmite.marc21(bibnumber)
        }.to raise_error(MetadataExtractor::Marmite::Client::Error,
                         "Could not retrieve MARC for #{bibnumber}. Error: #{raw_marmite_error}")
      end
    end

    context 'when request is unsuccessful due to an invalid bib number' do
      let(:marmite_error) { "Bib not found in Alma for #{bibnumber}" }

      before do
        stub_request(:get, "#{url}/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 404, body: { errors: [marmite_error] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises exception' do
        expect {
          marmite.marc21(bibnumber)
        }.to raise_error(MetadataExtractor::Marmite::Client::Error,
                         "Could not retrieve MARC for #{bibnumber}. Error: #{marmite_error}")
      end
    end
  end

  describe '#url_for' do
    let(:marmite) { described_class.new(url: url) }

    it 'correctly creates url' do
      expect(
        marmite.send(:url_for, 'cool/new/path?query=keyword')
      ).to eql "#{url}/cool/new/path?query=keyword"
    end

    context 'when error parsing url' do
      let(:marmite) { described_class.new(url: 'something/not/right') }

      it 'raises exception' do
        expect {
          marmite.send(:url_for, 'api/v2/records/sample?bib/marc21')
        }.to raise_error(MetadataExtractor::Marmite::Client::Error, /Error generating valid Marmite url/)
      end
    end
  end
end
