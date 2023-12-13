# frozen_string_literal: true

describe 'Items Requests' do
  before { sign_in create(:user, user_role) }

  # POST /resources/items
  context 'when creating an Item' do
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

      it 'creates the Item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: ItemResource).count
        ).to be 1
      end
    end
  end

  # PATCH /resources/items/:id
  context 'when editing an Item' do
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
  end

  # DELETE /resources/items/:id
  context 'when deleting an Item' do
    let(:user_role) { :admin }
    let(:item) { persist(:item_resource) }

    context 'with a successful request' do
      before { delete item_path(item) }

      it 'displays successful alert' do
        follow_redirect!
        expect(response.body).to include('Successfully deleted Item')
      end

      it 'deletes the Item' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: ItemResource).count
        ).to be 0
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
  end
end
