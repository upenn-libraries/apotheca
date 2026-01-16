# frozen_string_literal: true

describe UpdateArkMetadata do
  let(:transaction) { described_class.new }

  describe '#call' do
    let(:item) { persist(:item_resource) }
    let(:result) { transaction.call(id: item.id) }

    context 'when EZID requests valid' do
      include_context 'with successful Alma request' do
        let(:xml) { File.read(file_fixture('marmite/marc_xml/manuscript-1.xml')) }
      end

      let(:item) { persist(:item_resource, :with_bibnumber) }
      let(:body) do
        <<~BODY.strip
          _profile: dc
          dc.creator: Sigebert, of Gembloux, approximately 1030-1112
          dc.title: [Partial copy of Chronicon]
          dc.date: 1900; 1475
          dc.type: Text
        BODY
      end
      let(:ezid_request) do
        stub_request(:post, %r{#{Ezid::Client.config.host}/id/.*})
          .with(
            basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
            headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
            body: body
          )
          .to_return do |request|
            {
              status: 200,
              headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
              body: "success: #{request.uri.path.split('/', 3).last}"
            }
          end
      end

      before { ezid_request }

      # Testing that both ILS and resource metadata is combined to create the metadata for the EZID request.
      it 'sends correct metadata to EZID' do
        expect(result.success?).to be true
        expect(ezid_request).to have_been_requested
      end
    end

    context 'when EZID request invalid' do
      include_context 'with unsuccessful requests to update EZID'

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns expected failure' do
        expect(result.failure[:error]).to be :failed_to_update_ezid_metadata
        expect(result.failure[:exception]).to be_an Exception
      end
    end
  end
end
