# frozen_string_literal: true

describe UnpublishItem do
  describe '#call' do
    let(:transaction) { described_class.new }
    let(:result) { transaction.call(id: item.id.to_s, updated_by: 'initiator@example.com') }
    let(:updated_item) { result.value! }
    let(:item) { persist(:item_resource, :published) }

    context 'with successful unpublish request' do
      before do
        stub_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")
          .with(
            headers: { 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
      end

      include_examples 'creates a resource event', :unpublish_item, 'initiator@example.com', true do
        let(:resource) { updated_item }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'publishes item' do
        result
        expect(a_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")).to have_been_made
      end

      it 'sets published flag to false' do
        expect(updated_item).to have_attributes(published: false)
      end
    end

    context 'with unsuccessful unpublish request' do
      before do
        stub_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")
          .with(
            headers: { 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(
            status: 500, body: { error: 'Crazy Solr error' }.to_json, headers: { 'Content-Type': 'application/json' }
          )
      end

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :error_unpublishing_item
      end

      it 'includes error message in json response' do
        expect(result.failure[:exception].message).to include 'Crazy Solr error'
      end
    end

    context 'when item is not present in remote system' do
      before do
        stub_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")
          .with(
            headers: { 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(status: 404, body: { error: 'Not Found' }.to_json, headers: { 'Content-Type': 'application/json' })
      end

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :error_unpublishing_item
      end

      it 'includes error message in json response' do
        expect(result.failure[:exception].message).to include 'Not Found'
      end
    end
  end
end
