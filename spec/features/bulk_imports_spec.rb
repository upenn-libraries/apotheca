# frozen_string_literal: true

describe 'BulkImport management' do
  shared_examples_for 'any logged in user' do
    before do
      sign_in user
    end

    context 'when viewing bulk imports index' do
      let!(:bulk_imports) { create_list(:bulk_import, 10) }

      before { visit bulk_imports_path }

      it 'lists all BulkExports' do
        expect(page).to have_text('.csv', count: bulk_imports.length)
        expect(page).to have_css('.bulk-imports-list__bulk-import', count: bulk_imports.length)
      end
    end

    context 'when viewing their queued bulk export' do
      let!(:user_import) { create(:bulk_import, :queued, created_by: user) }

      it 'shows a cancel button' do
        expect(page).to have_link('Cancel', href: cancel_bulk_import_path(user_import.id))
      end
    end
  end

  context 'with a viewer' do
    let(:user) { create(:user, :viewer) }

    context 'when viewing item index page' do
      before do
        sign_in user
        visit bulk_imports_path
      end

      it 'does not show button to create new bulk import' do
        expect(page).not_to have_link('New Bulk Import', href: new_bulk_import_path)
      end
    end
  end

  context 'with an editor' do
    let(:user) { create(:user, :editor) }

    context 'when viewing item index page' do
      before do
        sign_in user
        visit bulk_imports_path
      end

      it 'shows button to create new bulk import' do
        expect(page).to have_link('New Bulk Import', href: new_bulk_import_path)
      end
    end
  end
end
