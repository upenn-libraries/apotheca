# frozen_string_literal: true

RSpec.describe 'SystemActions requests' do
  # GET /system_actions
  context 'when viewing system actions listing' do
    context 'with an unauthenticated user' do
      it 'redirects user to the root path' do
        get system_actions_path
        expect(response).to redirect_to(root_path)
        expect(flash['alert']).to include 'You need to sign in'
      end
    end

    context 'with an unauthorized user' do
      before { sign_in create(:user, :editor) }

      it 'redirects viewer users to authenticated root path with authorization message' do
        get system_actions_path
        expect(response).to redirect_to(authenticated_root_path)
        expect(flash['alert']).to include 'not authorized'
      end
    end

    context 'with an authorized user' do
      before { sign_in create(:user, :admin) }

      it 'shows the system actions index page' do
        get system_actions_path
        expect(response).to have_http_status :ok
      end
    end
  end

  # POST /system_actions/refresh_all_ils_metadata
  context 'when refreshing all ILS metadata' do
    before { sign_in create(:user, role) }

    context 'with an authorized user' do
      let(:role) { :admin }

      before do
        post refresh_all_ils_metadata_system_actions_path
      end

      it 'displays a job enqueued alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.refresh_all_ILS.success')
      end

      it 'enqueues the job' do
        expect(EnqueueBulkRefreshIlsMetadataJob).to have_enqueued_sidekiq_job.with any_args
      end
    end

    context 'when an error occurs while enqueueing the job' do
      let(:role) { :admin }

      before do
        allow(EnqueueBulkRefreshIlsMetadataJob).to receive(:perform_async).and_return(nil)

        post refresh_all_ils_metadata_system_actions_path, params: { form: 'refresh_all_ILS_metadata' }
      end

      it 'displays failure alert' do
        follow_redirect!
        expect(response.body).to include I18n.t('actions.item.refresh_all_ILS.failure')
      end
    end

    context 'with an unauthorized user' do
      let(:role) { :editor }

      before { post refresh_all_ils_metadata_system_actions_path }

      it 'displays failure alert' do
        expect(response).to redirect_to(authenticated_root_path)
        expect(flash['alert']).to include 'not authorized'
      end
    end
  end
end
