# frozen_string_literal: true

describe 'Items Requests' do
  before { sign_in create(:user, user_role) }

  # POST /resources/items
  context 'when creating an item' do
    include_context 'with successful requests to mint EZID'

    let(:user_role) { :editor }
    let(:item) { build(:item_resource) }

    context 'with a successful request' do
      before do
        post items_path, params: { item: { human_readable_name: item.human_readable_name,
                                           created_by: item.created_by,
                                           descriptive_metadata: {
                                             title: [{ value: item.descriptive_metadata.title.first.value }]
                                           } } }
      end

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include('Successfully created item.')
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
        post items_path, params: { item: { human_readable_name: item.human_readable_name,
                                           created_by: item.created_by } }
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
        expect(response.body).to include('Successfully updated item.')
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
        expect(response.body).to include('Successfully deleted Item')
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
        expect(response.body).to include('Job to refresh ILS metadata enqueued')
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
        expect(response.body).to include('An error occurred while enqueuing job to refresh ILS metadata')
      end
    end
  end
end
