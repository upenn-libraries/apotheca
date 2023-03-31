# frozen_string_literal: true

describe 'Import Show Page' do
  let(:user) { create(:user, role) }

  shared_examples_for 'any logged in user' do
    let(:import) { create(:import, :successful, duration: 60) }
    let(:import_with_errors) { create(:import, :failed) }

    before do
      sign_in user
      visit bulk_import_import_path(import.bulk_import, import)
    end

    it 'displays the state' do
      expect(page).to have_text(import.state.titlecase)
    end

    it 'displays the processing time' do
      expect(page).to have_text('1 minute')
    end

    it 'displays the resource_identifier' do
      expect(page).to have_text(import.resource_identifier)
    end

    it 'displays the id' do
      expect(page).to have_text(import.id)
    end

    it 'displays created_at' do
      expect(page).to have_text(import.created_at.to_fs(:display))
    end

    it 'displays updated_at' do
      expect(page).to have_text(import.updated_at.to_fs(:display))
    end

    it 'displays import_data' do
      expect(page).to have_text(import.import_data['human_readable_name'])
    end

    it 'displays any errors' do
      visit bulk_import_import_path(import_with_errors.bulk_import, import_with_errors)
      expect(page).to have_text(import_with_errors.process_errors.join(' '))
    end
  end

  shared_examples_for 'any user that can update their own Import' do
    let(:bulk_import) { create(:bulk_import, created_by: user) }
    let(:import) { create(:import, :queued, bulk_import: bulk_import) }

    before do
      sign_in user
      visit bulk_import_import_path(import.bulk_import, import)
    end

    it 'displays button to cancel queued import' do
      expect(page).to have_button('Cancel')
    end

    it 'can cancel a queued import' do
      click_on 'Cancel'
      expect(page).to have_text("Import #{import.id} cancelled")
      expect(page).not_to have_button('Cancel')
    end
  end

  shared_examples_for 'any user that cannot update an import belonging to other users' do
    let(:bulk_import) { create(:bulk_import) }
    let(:import) { create(:import, :queued, bulk_import: bulk_import) }

    before do
      sign_in user
      visit bulk_import_import_path(import.bulk_import, import)
    end

    it 'does not display button to cancel queued import' do
      expect(page).not_to have_button('Cancel')
    end
  end

  context 'with a viewer' do
    let(:role) { :viewer }

    it_behaves_like 'any logged in user'

    it_behaves_like 'any user that cannot update an import belonging to other users'
  end

  context 'with an editor' do
    let(:role) { :editor }

    it_behaves_like 'any logged in user'

    it_behaves_like 'any user that can update their own Import'

    it_behaves_like 'any user that cannot update an import belonging to other users'
  end

  context 'with an admin' do
    let(:role) { :admin }
    let(:bulk_import) { create(:bulk_import) }
    let(:import) { create(:import, :queued, bulk_import: bulk_import) }

    before do
      sign_in user
      visit bulk_import_import_path(import.bulk_import, import)
    end

    it_behaves_like 'any logged in user'

    it_behaves_like 'any user that can update their own Import'


    it 'displays button to cancel queued import that belongs to other user' do
      expect(page).to have_button('Cancel')
    end

    it 'can cancel a queued import belonging to other user' do
      click_on 'Cancel'
      expect(page).to have_text("Import #{import.id} cancelled")
      expect(page).not_to have_button('Cancel')
    end
  end

end
