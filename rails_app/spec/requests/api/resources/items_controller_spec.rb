# frozen_string_literal: true

describe 'Resource Item API' do
  describe 'GET #show' do
    context 'when no resource is found' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        get api_item_resource_path('1234-fooo-5678-quux')
      end

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_found')
      end
    end

    context 'with an unpublished ItemResource' do
      let(:item) { persist(:item_resource) }

      before { get api_item_resource_path(item.id) }

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:not_found)
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_published')
      end
    end

    context 'with an identifier for an AssetResource' do
      let(:asset) { persist(:asset_resource) }

      before { get api_item_resource_path(asset.id) }

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:bad_request)
        expect(json_body[:message]).to eq I18n.t('api.exceptions.resource_mismatch', resource: ItemResource.to_s)
      end
    end

    context 'with an error that does not have explicit handling' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::StaleObjectError)
        get api_item_resource_path('1234-fooo-5678-quux')
      end

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'with ItemResource information only' do
      let!(:item) do
        persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives)
      end
      let(:item_json) { json_body[:data][:item] }

      before { get api_item_resource_path(item.id, assets: 'true'), headers: { 'ACCEPT' => 'application/json' } }

      it 'returns item identifiers' do
        expect(item_json[:id]).to eq item.id.to_s
        expect(item_json[:ark]).to eq item.unique_identifier
      end

      it 'returns first and last published_at' do
        expect(item_json[:first_published_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(item_json[:last_published_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      it 'includes descriptive metadata' do
        expect(item_json).to have_key :descriptive_metadata
        expect(item_json[:descriptive_metadata].keys).to match_array(ItemResource::DescriptiveMetadata::Fields.all)
      end

      %i[preview pdf iiif_manifest].each do |type|
        it "includes item-level #{type} derivatives" do
          expect(item_json[:derivatives][type]).to match(
            mime_type: an_instance_of(String),
            size_bytes: an_instance_of(Integer),
            url: a_string_starting_with('http://www.example.com/')
          )
        end
      end

      it 'includes related assets' do
        expect(json_body[:data][:related][:assets]).to eql "http://www.example.com/v1/items/#{item.id}?assets=true"
      end
    end

    context 'with AssetResource information included' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives) }
      let(:item_json) { json_body[:data][:item] }

      before do
        get api_item_resource_path(item.id, assets: 'true'), headers: { 'ACCEPT' => 'application/json' }
      end

      it 'includes asset information if requested' do
        expect(item_json[:assets].count).to be 2
        expect(item_json[:assets].first.keys).to contain_exactly(:id, :label, :preservation_file, :derivatives)
      end
    end
  end

  describe 'GET #lookup' do
    context 'with an invalid ark' do
      it 'raises a routing error' do
        expect { get '/v1/items/lookup/ark:/abcd/456' }.to(raise_error(ActionController::RoutingError))
      end
    end

    context 'when no resource is found' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find)
          .and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        get api_ark_lookup_path('ark:/123/456')
      end

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_found')
      end
    end

    context 'with an unpublished ItemResource' do
      let(:item) { persist(:item_resource) }

      before { get api_ark_lookup_path(item.unique_identifier) }

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:not_found)
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_published')
      end
    end

    context 'with an error that does not have explicit handling' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::StaleObjectError)
        get api_ark_lookup_path('ark:/123/456')
      end

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'with a successful lookup' do
      let!(:item) do
        persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives)
      end
      let(:item_json) { json_body[:data][:item] }

      before { get api_ark_lookup_path(item.unique_identifier), headers: { 'ACCEPT' => 'application/json' } }

      it 'returns item identifiers' do
        expect(item_json[:id]).to eq item.id.to_s
        expect(item_json[:ark]).to eq item.unique_identifier
      end

      it 'returns first and last published_at' do
        expect(item_json[:first_published_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(item_json[:last_published_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      it 'includes descriptive metadata' do
        expect(item_json).to have_key :descriptive_metadata
        expect(item_json[:descriptive_metadata].keys).to match_array(ItemResource::DescriptiveMetadata::Fields.all)
      end

      %i[preview pdf iiif_manifest].each do |type|
        it "includes item-level #{type} derivatives" do
          expect(item_json[:derivatives][type]).to match(
            mime_type: an_instance_of(String),
            size_bytes: an_instance_of(Integer),
            url: a_string_starting_with('http://www.example.com/')
          )
        end
      end

      it 'includes related assets' do
        expect(json_body[:data][:related][:assets]).to eql "http://www.example.com/v1/items/#{item.id}?assets=true"
      end
    end
  end

  describe 'GET #preview' do
    let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged) }
    let(:size) { nil }

    before { get api_item_preview_path(item.id, size: size) }

    context 'when size is not provided' do
      it 'redirects to presigned_url for thumbnail' do
        url = %r{\A#{Settings.minio.endpoint}/#{Settings.derivative_storage.bucket}/#{item.thumbnail.id}/thumbnail}
        expect(response).to redirect_to(url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when size is default size' do
      let(:size) { "#{API::Resources::ItemsController::DEFAULT_SIZE},#{API::Resources::ItemsController::DEFAULT_SIZE}" }

      it 'redirects to presigned_url for thumbnail' do
        url = %r{\A#{Settings.minio.endpoint}/#{Settings.derivative_storage.bucket}/#{item.thumbnail.id}/thumbnail}
        expect(response).to redirect_to(url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when size is 400,400' do
      let(:size) { '400,400' }

      it 'redirects to IIIF image server' do
        url = %r{\A#{Settings.image_server.url}/iiif/3/#{item.thumbnail.id}%2Fiiif_image/full/!#{size}/0/default.jpg}
        expect(response).to redirect_to(url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when size is greater than 600,600' do
      let(:size) { '800,800' }

      it 'returns a 400 status code' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.invalid_param.size')
      end
    end

    context 'when size is invalid' do
      let(:size) { '600' }

      it 'returns a 400 status code' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.invalid_param.size')
      end
    end

    context 'when item\'s thumbnail is not an image' do
      let(:asset) { persist(:asset_resource, :with_audio_file, :with_derivatives, :with_metadata) }
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged, asset1: asset) }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.file_not_found')
      end
    end
  end

  describe 'GET #pdf' do
    before { get api_item_pdf_path(item.id) }

    context 'when PDF is available' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives) }

      it 'redirects to a PDF download' do
        expected_presigned_url = %r{\A#{Settings.minio.endpoint}/#{Settings.derivative_storage.bucket}/#{item.id}/pdf}
        expect(response).to redirect_to(expected_presigned_url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when PDF is not available' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged) }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.file_not_found')
      end
    end
  end
end
