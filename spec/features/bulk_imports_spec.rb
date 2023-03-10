# frozen_string_literal: true

describe 'BulkImport Management' do
  context 'when viewing bulk imports index' do
    let(:user) { create :user, role }

    before { sign_in user }

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
        expect(page).to have_button('Cancel', type: "submit")
      end

      it 'can cancel all queued imports' do
        click_on 'Cancel'
        expect(page).to have_text('All queued imports were cancelled')
        expect(page).not_to have_button('Cancel')
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
        expect(page).to have_button('Cancel', type: "submit")
        click_on 'Cancel'
        expect(page).to have_text('All queued imports were cancelled')
      end
    end
  end

  context 'when viewing bulk import show' do
    shared_examples_for 'any logged in user' do
      before { sign_in user }

      context 'when viewing the bulk import show page' do
        let(:bulk_import) { create(:bulk_import, note: 'Test') }
        let!(:successful_imports) { create_list(:import, 5, :successful, duration: 60, bulk_import: bulk_import) }
        let(:failed_imports) { create_list(:import, 5, :failed, bulk_import: bulk_import) }

        before { visit bulk_import_path(bulk_import) }

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

    shared_examples_for 'a user that cannot update bulk imports belonging to other users' do
      before { sign_in user }

      context 'when viewing a bulk import show page that belongs to another user' do
        let!(:bulk_import) { create(:bulk_import) }
        let!(:queued_import) { create(:import, :queued, bulk_import: bulk_import) }

        before { visit bulk_import_path(bulk_import) }

        it 'does not display a button to cancel all queued imports' do
          expect(page).not_to have_button('Cancel All Queued Imports')
        end

        it 'does not display a cancel button for each queued import' do
          expect(page).not_to have_button('Cancel', exact: true, count: 1)
        end
      end
    end

    shared_examples_for 'a user that can update their own bulk imports' do
      before { sign_in user }

      context 'when viewing their bulk import show page' do
        let(:bulk_import) { create(:bulk_import, created_by: user) }
        let!(:queued_imports) { create_list(:import, 5, :queued, bulk_import: bulk_import) }

        before { visit bulk_import_path(bulk_import) }

        it 'displays a button to cancel all queued imports' do
          expect(page).to have_button('Cancel All Queued Imports')
        end

        it 'displays a cancel button for each queued import' do
          expect(page).to have_button('Cancel', exact: true, count: queued_imports.count)
        end

        it 'can cancel all queued imports' do
          click_on 'Cancel All Queued Imports'
          expect(page).to have_text('All queued imports were cancelled')
          expect(page).not_to have_button('Cancel')
        end

        it 'can cancel an individual Import' do
          within '#imports-table > tbody > tr:first-child' do
            click_on 'Cancel'
          end
          expect(page).to have_text("Import #{queued_imports.first.id} cancelled")
        end

      end

      context 'when viewing their bulk import that has no cancellable imports' do
        let(:bulk_import) { create(:bulk_import, created_by: user) }
        let!(:import) { create(:import, :successful, bulk_import: bulk_import) }

        before { visit bulk_import_path(bulk_import) }

        it 'does not display a button to cancel all queued imports' do
          expect(page).not_to have_button('Cancel All Queued Imports')
        end

        it 'does not display a button to cancel individual imports' do
          expect(page).not_to have_button('Cancel', exact: true)
        end
      end
    end

    context 'with a viewer' do
      let(:viewer) { create(:user, :viewer) }

      it_behaves_like 'any logged in user' do
        let(:user) { viewer }
      end

      it_behaves_like 'a user that cannot update bulk imports belonging to other users' do
        let(:user) { viewer }
      end
    end

    context 'with an editor' do
      let(:editor) { create(:user, :editor) }

      it_behaves_like 'any logged in user' do
        let(:user) { editor }
      end

      it_behaves_like 'a user that cannot update bulk imports belonging to other users' do
        let(:user) { editor }
      end

      it_behaves_like 'a user that can update their own bulk imports' do
        let(:user) { editor }
      end
    end

    context 'with an admin' do
      let(:admin) { create(:user, :admin) }

      it_behaves_like 'any logged in user' do
        let(:user) { admin }
      end

      it_behaves_like 'a user that can update their own bulk imports' do
        let(:user) { admin }
      end

      context 'when viewing a bulk import created by another user' do
        let(:bulk_import) { create(:bulk_import) }
        let!(:queued_import) { create(:import, :queued, bulk_import: bulk_import) }

        before do
          sign_in admin
          visit bulk_import_path(bulk_import)
        end

        it 'displays a button to cancel all imports' do
          expect(page).to have_button('Cancel All Queued Imports')
        end

        it 'displays a cancel button for each queued import' do
          expect(page).to have_button('Cancel', exact: true, count: 1)
        end
      end
    end
  end
end
