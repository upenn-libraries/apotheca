# frozen_string_literal: true

describe 'Items Requests' do
  before { sign_in create(:user, user_role) }

  # Authentication check
  context 'when editing' do
    let(:item) { persist(:item_resource) }

    context 'without edit role' do
      let(:user_role) { :viewer }

      it 'redirects viewer users to authenticated root path with authorization message' do
        get edit_item_path(item)
        expect(response).to redirect_to(authenticated_root_path)
        expect(flash['alert']).to include 'not authorized'
      end
    end

    context 'with proper role' do
      let(:user_role) { :editor }

      it 'shows item edit form' do
        get edit_item_path(item)
        expect(response).to have_http_status :ok
      end
    end
  end

  # POST /resources/items
  context 'when creating an item' do
    include_context 'with successful requests to mint EZID'

    let(:user_role) { :editor }

    context 'with a successful request' do
      before do
        post items_path, params: { item: { human_readable_name: 'Book Name',
                                           created_by: 'test@test.com',
                                           descriptive_metadata: {
                                             title: [{ value: 'Book Title' }]
                                           } } }
      end

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.create.success')
      end

      it 'creates the item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: ItemResource).count
        ).to be 1
      end
    end

    context 'when an error is raised in CreateAsset transaction' do
      before do
        # Don't include Title in request, validation will fail
        post items_path, params: { item: { human_readable_name: 'The Readable Name',
                                           created_by: 'test@test.com' } }
      end

      it 'displays failure alert' do
        expect(response.body).to include 'Validation Failed'
      end

      it 'does not create the item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: ItemResource).count
        ).to be 0
      end
    end
  end

  # PATCH /resources/items/:id
  context 'when updating an item' do
    let(:user_role) { :editor }
    let(:item) { persist(:item_resource) }

    context 'with a successful request' do
      before { patch item_path(item), params: { item: { human_readable_name: 'The new name!' } } }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.update.success')
      end

      it 'updates the Item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: item.id).human_readable_name
        ).to eq('The new name!')
      end
    end

    context 'when an error is raised in the UpdateItem transaction' do
      before do
        step_double = instance_double(Steps::Validate)
        allow(Steps::Validate).to receive(:new).and_return(step_double)
        allow(step_double).to receive(:call) { Dry::Monads::Failure.new(error: :step_failed) }

        patch item_path(item), params: { form: 'descriptive-metadata', item: { human_readable_name: 'The new name!' } }
      end

      it 'displays failure alert' do
        expect(response.body).to include('Step Failed')
      end

      it 'does not update the item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: item.id).human_readable_name
        ).not_to eq('The new name!')
      end
    end
  end

  # DELETE /resources/items/:id
  context 'when deleting an item' do
    let(:user_role) { :admin }
    # need full asset on the item to redirect to asset show after failed deletion
    let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

    context 'with a successful request' do
      before { delete item_path(item) }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.delete.success')
      end

      it 'deletes the item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: ItemResource).count
        ).to be 0
      end
    end

    context 'when an error is raised in the DeleteItem transaction' do
      before do
        step_double = instance_double(Steps::DeleteResource)
        allow(Steps::DeleteResource).to receive(:new).and_return(step_double)
        allow(step_double).to receive(:call) { Dry::Monads::Failure.new(error: :delete_failed) }

        delete item_path(item), params: { form: 'delete_item' }
      end

      it 'displays failure alert' do
        expect(response.body).to include('Delete Failed')
      end

      it 'does not delete the item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: ItemResource).count
        ).to be 1
      end
    end
  end

  # POST /resources/items/:id/refresh_ils_metadata
  context 'when refreshing ILS metadata' do
    let(:user_role) { :admin }
    let(:item) { persist(:item_resource) }

    context 'with a successful request' do
      before { post refresh_ils_metadata_item_path(item) }

      it 'displays job enqueued alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.refresh_ILS.success')
      end

      it 'enqueues job' do
        expect(RefreshIlsMetadataJob).to have_enqueued_sidekiq_job.with(item.id, any_args)
      end
    end

    context 'when an error occurs while enqueueing the job' do
      before do
        allow(RefreshIlsMetadataJob).to receive(:perform_async).and_return(nil)

        post refresh_ils_metadata_item_path(item), params: { form: 'refresh_ILS_metadata' }
      end

      it 'displays failure alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.refresh_ILS.failure')
      end
    end
  end

  # POST /resources/items/:id/publish
  context 'when publishing an item' do
    let(:user_role) { :editor }
    let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

    context 'with a successful request' do
      before { post publish_item_path(item) }

      it 'displays job enqueued alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.publish.success')
      end

      it 'enqueues job' do
        expect(PublishItemJob).to have_enqueued_sidekiq_job.with(item.id, any_args)
      end
    end

    context 'when an error occurs while enqueueing the job' do
      before do
        allow(PublishItemJob).to receive(:perform_async).and_return(nil)

        post publish_item_path(item), params: { form: 'publish_item' }
      end

      it 'displays failure alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.publish.failure')
      end
    end
  end

  # POST /resources/items/:id/unpublish
  context 'when unpublishing an item' do
    let(:user_role) { :editor }
    let(:item) { persist(:item_resource, :published) }

    context 'with a successful request' do
      before do
        stub_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")
          .with(headers: { 'Authorization': "Token token=#{Settings.publish.token}" })
          .to_return(status: 200, headers: { 'Content-Type': 'application/json' })

        post unpublish_item_path(item)
      end

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.unpublish.success')
      end

      it 'unpublishes item' do
        updated_item = Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: item.id)
        expect(updated_item.published).to be false
      end
    end

    context 'when an error is raised in the UnpublishItem transaction' do
      before do
        stub_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")
          .with(headers: { 'Authorization': "Token token=#{Settings.publish.token}" })
          .to_return(
            status: 500, body: { error: 'Crazy Solr error' }.to_json, headers: { 'Content-Type': 'application/json' }
          )

        post unpublish_item_path(item), params: { form: 'unpublish_item' }
      end

      it 'displays failure alert' do
        expect(response.body).to include('Crazy Solr error')
      end

      it 'does not unpublish item' do
        updated_item = Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: item.id)
        expect(updated_item.published).to be true
      end
    end
  end
end
