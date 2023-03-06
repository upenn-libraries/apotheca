# frozen_string_literal: true

describe 'BulkImport Management' do

  shared_examples_for 'any logged in user' do
    before { sign_in user }

    context 'when viewing the bulk import show page' do
      let(:bulk_import) { create(:bulk_import, note: 'Test') }
      let!(:successful_imports) { create_list(:import, 5, :successful, duration: 60, bulk_import: bulk_import) }
      let(:failed_imports) { create_list(:import, 5, :failed, bulk_import: bulk_import) }

      before { visit "#{bulk_imports_path}/#{bulk_import.id}" }

      it 'displays original_filename' do
        within('#bulk-import-dl') { expect(page).to have_text(bulk_import.original_filename) }
      end

      it 'has link to download csv' do
        href = csv_bulk_import_path(bulk_import)
        within('#bulk-import-dl') { expect(page).to have_link('Download CSV', href:) }
      end

      it 'displays the total number of imports' do
        within('#bulk-import-dl') { expect(page).to have_text(bulk_import.imports.length.to_s) }
      end

      it 'displays total processing time' do
        within('#bulk-import-dl') { expect(page).to have_text("#{successful_imports.count} minutes") }
      end

      it 'displays the note' do
        within('#bulk-import-dl') { expect(page).to have_text(bulk_import.note) }
      end

      it 'displays the ID' do
        within('#bulk-import-dl') { expect(page).to have_text(bulk_import.id.to_s) }
      end

      it 'displays the email of the creator' do
        within('#bulk-import-dl') { expect(page).to have_text(bulk_import.created_by.email) }
      end

      it 'displays the created_at timestamp' do
        within('#bulk-import-dl') { expect(page).to have_text(bulk_import.created_at.to_fs(:display)) }
      end

      it 'displays all imports' do
        expect(page).to have_link('All', class: 'active')
        within('#imports-table') { expect(page).to have_link('Details', count: bulk_import.imports.count) }
      end

      it 'only displays imports in a particular state' do
        click_link Import::STATE_SUCCESSFUL.to_s
        expect(page).to have_link(Import::STATE_SUCCESSFUL.to_s, class: 'active')
        within('#imports-table') { expect(page).to have_link('Details', count: successful_imports.count) }
      end

      it 'disables tab if there are no imports in that state' do
        within('#import-states-tabs') do
          expect(page).to have_link(Import::STATE_CANCELLED.to_s, href: '', class: 'disabled')
        end
      end

    end
  end

  shared_examples_for 'viewers and editors' do
    before { sign_in user }

    context 'when viewing a bulk import show page that belongs to another user' do
      let!(:bulk_import) { create(:bulk_import) }
      let!(:queued_import) { create(:import, :queued, bulk_import:) }

      before { visit "#{bulk_imports_path}/#{bulk_import.id}" }

      it 'does not display a button to cancel all queued imports' do
        expect(page).not_to have_button('Cancel All Queued Imports')
      end

      it 'does not display a cancel button for each queued import' do
        expect(page).not_to have_button('Cancel', exact: true, count: 1)
      end
    end
  end

  shared_examples_for 'editors and admins' do
    before { sign_in user }

    context 'when viewing their bulk import show page' do

      let(:bulk_import) { create(:bulk_import, created_by: user) }
      let!(:queued_imports) { create_list(:import, 5, :queued, bulk_import:) }

      before { visit "#{bulk_imports_path}/#{bulk_import.id}" }

      it 'displays a button to cancel all queued imports' do
        expect(page).to have_button('Cancel All Queued Imports')
      end

      it 'displays a cancel button for each queued import' do
        expect(page).to have_button('Cancel', exact: true, count: queued_imports.count)
      end

    end

  end

  context 'with a viewer' do
    let(:viewer) { create(:user, :viewer) }

    context 'when viewing any bulk import show page' do
      it_behaves_like 'any logged in user' do
        let(:user) { viewer }
      end
    end

    context 'when viewing a bulk import created by another user' do
      it_behaves_like 'viewers and editors' do
        let(:user) { viewer }
      end
    end
  end

  context 'with an editor' do
    let(:editor) { create(:user, :editor) }

    context 'when viewing any bulk import show page' do

      it_behaves_like 'any logged in user' do
        let(:user) { editor }
      end
    end

    context 'when viewing their bulk import show page' do
      it_behaves_like 'editors and admins' do
        let(:user) { editor }
      end
    end

    context 'when viewing a bulk import created by another user' do
      it_behaves_like 'viewers and editors' do
        let(:user) { editor }
      end
    end
  end

  context 'with an admin' do
    let(:admin) { create(:user, :admin) }

    context 'when viewing any bulk import show page' do

      it_behaves_like 'any logged in user' do
        let(:user) { admin }
      end
    end

    context 'when viewing their bulk import show page' do

      it_behaves_like 'editors and admins' do
        let(:user) { admin }
      end
    end

    context 'when viewing a bulk import created by another user' do
      let(:bulk_import) { create(:bulk_import) }
      let!(:queued_import) { create(:import, :queued, bulk_import:) }

      before do
        sign_in admin
        visit "#{bulk_imports_path}/#{bulk_import.id}"
      end

      it 'displays a button to cancel all queued imports' do
        expect(page).to have_button('Cancel All Queued Imports')
      end

      it 'displays a cancel button for each queued import' do
        expect(page).to have_button('Cancel', exact: true, count: 1)
      end
    end
  end
end


