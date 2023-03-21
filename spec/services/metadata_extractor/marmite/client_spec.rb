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
    let(:bibnumber) { 'sample_bib' }

    context 'when request is successful' do
      let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }

      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 200, body: marc_xml, headers: {})
      end

      it 'returns expected MARC XML' do
        expect(marmite.marc21(bibnumber)).to eql marc_xml
      end
    end

    context 'when request is unsuccessful' do
      let(:marmite_error) { ["Record #{bibnumber} in marc21 format not found"] }

      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 404, body: JSON.generate(errors: marmite_error), headers: {})
      end

      it 'raises exception' do
        expect {
          marmite.marc21(bibnumber)
        }.to raise_error(MetadataExtractor::Marmite::Client::Error, "Could not retrieve MARC for #{bibnumber}. Error: #{marmite_error.join(' ')}")
      end
    end

    context 'when saving record with invalid bib number' do
      let(:marmite_error) { 'Internal Server Error' }

      before do
        stub_request(:get, "https://marmite.library.upenn.edu:9292/api/v2/records/#{bibnumber}/marc21?update=always")
          .to_return(status: 500, body: marmite_error, headers: {})
      end

      it 'raises exception' do
        expect {
          marmite.marc21(bibnumber)
        }.to raise_error(MetadataExtractor::Marmite::Client::Error, "Could not retrieve MARC for #{bibnumber}. Error: #{marmite_error}")
      end
    end
  end

  describe '#url_for' do
    let(:marmite) { described_class.new(url: url) }

    it 'correctly creates url' do
      expect(
        marmite.send(:url_for, 'cool/new/path?query=keyword')
      ).to eql 'https://marmite.library.upenn.edu:9292/cool/new/path?query=keyword'
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
