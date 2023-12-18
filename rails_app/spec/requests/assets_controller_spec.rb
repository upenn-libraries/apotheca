# frozen_string_literal: true

describe 'Asset Requests' do
  before { sign_in create(:user, user_role) }

  # GET /resources/assets/:id/file/:type
  context 'when downloading files' do
    let(:user_role) { :viewer }

    context 'with errors' do
      let(:asset) { persist :asset_resource }

      it 'responds with a 400 when given an unsupported type' do
        get file_asset_path(asset, type: :monochrome)
        expect(response).to have_http_status :bad_request
      end

      it 'responds with a 500 when the requested asset does not exist' do
        get file_asset_path('bad-asset-uuid', type: :preservation)
        expect(response).to have_http_status :not_found
      end
    end

    context 'when the file exists' do
      let(:asset) { persist :asset_resource, :with_preservation_file }

      before { get file_asset_path(asset, type: :preservation) }

      it 'returns a successful response' do
        expect(response).to have_http_status :ok
      end

      it 'has the correct Content-Type header' do
        expect(response.headers['Content-Type']).to eq 'image/tiff'
      end

      it 'has the correct filename' do
        expect(response.headers['Content-Disposition']).to include 'filename="front.tif"'
      end

      it 'has the correct disposition' do
        expect(response.headers['Content-Disposition']).to include 'attachment;'
      end
    end
  end

  # POST /resources/assets
  context 'when creating asset' do
    let(:user_role) { :editor }
    let(:item) { persist :item_resource }
    let(:file) { fixture_file_upload('files/trade_card/original/front.tif') }

    context 'with a successful request' do
      before { post assets_path, params: { item_id: item.id, asset: { file: file } } }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.asset.create.success')
      end

      it 'creates the asset' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: AssetResource).count
        ).to be 1
      end

      it 'records events' do
        # create, update, attach
        expect(ResourceEvent.all.count).to be 3
      end
    end

    context 'when an error is raised in CreateAsset transaction' do
      before do
        # Returning a virus check failure when creating the asset.
        transaction_double = instance_double(CreateAsset)
        allow(CreateAsset).to receive(:new).and_return(transaction_double)
        allow(transaction_double).to receive(:call).with(any_args) do
          Dry::Monads::Failure.new(error: :create_failed)
        end

        post assets_path, params: { item_id: item.id, asset: { file: file } }
      end

      it 'displays error' do
        expect(response.body).to include('Create Failed')
      end

      it 'does not create an asset' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service
                                   .find_all_of_model(model: AssetResource).count
        ).to be 0
      end

      it 'does not record any events' do
        expect(ResourceEvent.all.count).to be 0
      end
    end

    context 'when uploading a file at least 2GB in size' do
      before do
        allow(ActionDispatch::Http::UploadedFile).to receive(:new).and_return(file)
        allow(file).to receive(:size).and_return(Settings.virus_check.size_threshold)

        post assets_path, params: { item_id: item.id, asset: { file: file } }
      end

      it 'displays error' do
        expect(flash[:alert]).to include(I18n.t('assets.file.size'))
      end
    end
  end

  # PATCH /resources/assets/:id
  context 'when updating asset' do
    let(:user_role) { :editor }
    let(:item) { persist :item_resource, :with_full_assets_all_arranged }
    let(:file) { fixture_file_upload('files/trade_card/original/front.tif') }

    context 'with a successful request' do
      before { patch asset_path(item.asset_ids.first), params: { asset: { label: 'a new label' } } }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.asset.update.success')
      end

      it 'updates the asset' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: item.asset_ids.first).label
        ).to eq('a new label')
      end

      it 'records an event' do
        expect(ResourceEvent.all.count).to be 1
      end
    end

    context 'when an error is raised in UpdateAsset transaction' do
      before do
        # Returning a virus check failure when creating the asset.
        transaction_double = instance_double(UpdateAsset)
        allow(UpdateAsset).to receive(:new).and_return(transaction_double)
        allow(transaction_double).to receive(:call).with(any_args) do
          Dry::Monads::Failure.new(error: :virus_detected)
        end

        # Request
        post assets_path, params: { item_id: item.id, asset: { file: file } }
      end

      it 'displays error' do
        expect(response.body).to include 'Virus Detected'
      end

      it 'does not create an asset' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service
                                   .find_all_of_model(model: AssetResource).count
        ).to be 2
      end

      it 'does not record any events' do
        expect(ResourceEvent.all.count).to be 0
      end
    end
  end

  # DELETE /resources/assets/:id
  context 'when deleting an asset' do
    let(:user_role) { :admin }
    let(:item) { persist :item_resource, :with_full_assets_all_arranged }

    context 'with a successful request' do
      before { delete asset_path(item.asset_ids.last) }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.asset.delete.success')
      end

      it 'deletes the asset' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service
                                   .find_all_of_model(model: AssetResource).count
        ).to be 1
      end

      it 'records an event' do
        # detach, delete
        expect(ResourceEvent.all.count).to be 2
      end
    end

    context 'when an error is raised in the DeleteAsset transaction' do
      before do
        step_double = instance_double(Steps::DeleteResource)
        allow(Steps::DeleteResource).to receive(:new).and_return(step_double)
        allow(step_double).to receive(:call) { Dry::Monads::Failure.new(error: :delete_failed) }

        delete asset_path(item.asset_ids.last)
      end

      it 'displays error' do
        expect(response.body).to include('Delete Failed')
      end

      it 'does not delete asset' do
        expect(item.asset_ids.count).to be 2
      end
    end

    context 'when the requested asset is the thumbnail' do
      before { delete asset_path(item.asset_ids.first) }

      it 'displays error' do
        expect(response.body).to include('This Asset Is Currently Designated As The Item Thumbnail.')
      end
    end
  end

  # POST /resources/assets/:id/regenerate_derivatives
  context 'when regenerating derivatives' do
    let(:user_role) { :admin }
    let(:item) { persist :item_resource, :with_full_assets_all_arranged }

    context 'with a successful request' do
      before { post regenerate_derivatives_asset_path(item.asset_ids.first) }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.asset.regenerate_derivatives.success')
      end

      it 'enqueues job' do
        expect(GenerateDerivativesJob).to have_enqueued_sidekiq_job.with(item.asset_ids.first, any_args)
      end
    end

    context 'when an error occurs while enqueueing the job' do
      before do
        allow(GenerateDerivativesJob).to receive(:perform_async).and_return(nil)
        post regenerate_derivatives_asset_path(item.asset_ids.first), params: { form: 'regenerate_derivatives' }
      end

      it 'displays failure alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.asset.regenerate_derivatives.failure')
      end
    end
  end
end
