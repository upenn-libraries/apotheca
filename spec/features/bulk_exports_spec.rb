# frozen_string_literal: true

describe 'BulkExport management' do
  shared_examples_for 'any logged in user' do
    before do
      persist(:item_resource)
      sign_in user
    end

    context 'when viewing bulk exports' do
      let!(:bulk_exports) { create_list(:bulk_export, 10) }

      before { visit bulk_exports_path }

      it 'lists all BulkExports' do
        expect(page).to have_text('Search Parameters', count: bulk_exports.length)
        expect(page).to have_css('.card', count: bulk_exports.length)
      end
    end

    context 'when viewing their queued bulk export' do
      let!(:user_export) { create(:bulk_export, user: user, state: BulkExport::STATE_QUEUED) }

      before { visit bulk_exports_path }

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'displays cancel button' do
        expect(page).to have_button('Cancel', count: 1)
      end

      it 'displays delete button' do
        expect(page).to have_button('Delete', count: 1)
      end

      it 'does not display regenerate button' do
        expect(page).not_to have_button('Regenerate')
      end
    end

    context 'when viewing their cancelled bulk export' do
      let!(:user_export) { create(:bulk_export, user: user, state: BulkExport::STATE_CANCELLED) }

      before { visit bulk_exports_path }

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'displays delete button' do
        expect(page).to have_button('Delete', count: 1)
      end

      it 'does not display cancel button' do
        expect(page).not_to have_button('Cancel')
      end

      it 'does not display regenerate button' do
        expect(page).not_to have_button('Regenerate')
      end
    end

    context 'when viewing their processing bulk export' do
      let!(:user_export) { create(:bulk_export, user: user, state: BulkExport::STATE_PROCESSING) }

      before { visit bulk_exports_path }

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'does not display any buttons' do
        expect(page).not_to have_button('Export')
      end
    end

    context 'when viewing their failed bulk export' do
      let!(:user_export) { create(:bulk_export, user: user, state: BulkExport::STATE_FAILED) }

      before { visit bulk_exports_path }

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'displays regenerate button' do
        expect(page).to have_button('Regenerate', count: 1)
      end

      it 'displays delete button' do
        expect(page).to have_button('Delete', count: 1)
      end

      it 'does not display cancel button' do
        expect(page).not_to have_button('Cancel')
      end
    end

    context 'when viewing their successful bulk export' do
      let!(:user_export) { create(:bulk_export, user: user, state: BulkExport::STATE_QUEUED) }

      before do
        user_export.process!
        visit bulk_exports_path
      end

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'displays link to download attached csv' do
        expect(page).to have_link('Download CSV', count: 1)
      end

      it 'displays regenerate button' do
        expect(page).to have_button('Regenerate', count: 1)
      end

      it 'displays delete button' do
        expect(page).to have_button('Delete', count: 1)
      end

      it 'does not display cancel button' do
        expect(page).not_to have_button('Cancel')
      end
    end
  end

  context 'with a viewer' do
    let(:viewer) { create(:user, :viewer) }

    it_behaves_like 'any logged in user' do
      let(:user) { viewer }
    end

    context 'when viewing bulk exports that belong to other users' do
      let!(:bulk_exports) { create_list(:bulk_export, 10) }

      before do
        sign_in viewer
        visit bulk_exports_path
      end

      it 'does not display the buttons' do
        expect(page).not_to have_button('Export')
      end
    end
  end

  context 'with an editor' do
    let(:editor) { create(:user, :editor) }

    it_behaves_like 'any logged in user' do
      let(:user) { editor }
    end

    context 'when viewing bulk exports that belong to other users' do
      let!(:bulk_exports) { create_list(:bulk_export, 10) }

      before do
        sign_in editor
        visit bulk_exports_path
      end

      it 'does not display the buttons' do
        expect(page).not_to have_button('Export')
      end
    end
  end

  context 'with and admin' do
    let(:admin) { create(:user, :admin) }

    it_behaves_like 'any logged in user' do
      let(:user) { admin }
    end

    context 'when viewing bulk exports that belong to other users' do
      let!(:bulk_exports) { create_list(:bulk_export, 10) }

      before do
        sign_in admin
        visit bulk_exports_path
      end

      it 'displays the buttons' do
        expect(page).to have_button('Export')
      end
    end
  end
end
