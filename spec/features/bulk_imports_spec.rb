# frozen_string_literal: true

describe 'BulkImport management' do
  before { sign_in user }

  context 'when viewing bulk imports index' do
    let(:user) { create :user, role }

    context 'with a viewer' do
      let(:role) { :viewer }

      before do
        create_list(:bulk_import, 1)
        visit bulk_imports_path
      end

      it 'lists all BulkImports' do
        expect(page).to have_text('.csv', count: 1)
        expect(page).to have_css('.bulk-imports-list__bulk-import', count: 1)
      end

      it 'does not show button to create new bulk import' do
        expect(page).not_to have_link('New Bulk Import', href: new_bulk_import_path)
      end

      it 'does not show cancel buttons' do
        expect(page).not_to have_link('Cancel')
      end
    end

    context 'with an editor' do
      let(:role) { :editor }
      let(:bulk_import) { create(:bulk_import, created_by: user) }

      before do
        create(:import, :queued, bulk_import: bulk_import)
        visit bulk_imports_path
      end

      it 'shows button to create new bulk import' do
        expect(page).to have_link('New Bulk Import', href: new_bulk_import_path)
      end

      it 'shows a cancel button' do
        expect(page).to have_link('Cancel', href: cancel_bulk_import_path(bulk_import.id))
      end
    end

    context 'with an admin' do
      let(:role) { :admin }
      let(:bulk_import) { create(:bulk_import) }

      before do
        create(:import, :queued, bulk_import: bulk_import)
        visit bulk_imports_path
      end

      it 'shows button to create new bulk import' do
        expect(page).to have_link('New Bulk Import', href: new_bulk_import_path)
      end

      it 'can cancel others\' bulk imports' do
        expect(page).to have_link('Cancel', href: cancel_bulk_import_path(bulk_import.id))
      end
    end
  end
end
