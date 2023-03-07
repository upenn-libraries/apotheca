# frozen_string_literal: true

describe 'BulkExport management' do
  shared_examples_for 'any logged in user' do
    before do
      persist(:item_resource)
      sign_in user
    end

    context 'when viewing bulk exports' do
      let!(:bulk_exports) { create_list(:bulk_export, 12) }

      before { visit bulk_exports_path }

      it 'lists all BulkExports' do
        expect(page).to have_text('Search Parameters', count: bulk_exports.length)
        expect(page).to have_css('.card', count: bulk_exports.length)
      end

      it 'stores per page value' do
        select '10', from: 'Per Page'
        click_on 'Submit'
        expect(page).to have_text('Displaying exports 1 - 10')
        click_on 'Items'
        click_on 'Exports'
        expect(page).to have_text('Displaying exports 1 - 10')
      end
    end

    context 'when viewing their queued bulk export' do
      let!(:user_export) { create(:bulk_export, :queued, created_by: user) }

      before { visit bulk_exports_path }

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'displays cancel button' do
        expect(page).to have_button('Cancel', count: 1)
      end

      it 'does not display delete button' do
        expect(page).not_to have_button('Delete', count: 1)
      end

      it 'does not display regenerate button' do
        expect(page).not_to have_button('Regenerate')
      end

      it 'can be cancelled' do
        click_on 'Cancel Export'
        expect(page).to have_text('Bulk export cancelled.')
      end
    end

    context 'when viewing their cancelled bulk export' do
      let!(:user_export) { create(:bulk_export, :cancelled, created_by: user) }

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

      it 'can be deleted' do
        click_on 'Delete Export'
        expect(page).to have_text('Bulk export deleted.')
      end
    end

    context 'when viewing their processing bulk export' do
      let!(:user_export) { create(:bulk_export, :processing, created_by: user) }

      before { visit bulk_exports_path }

      it 'displays the correct state' do
        expect(page).to have_text(user_export.state.titleize)
      end

      it 'does not display any buttons' do
        expect(page).not_to have_button('Export')
      end
    end

    context 'when viewing their failed bulk export' do
      let!(:user_export) { create(:bulk_export, :failed, created_by: user) }

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

      it 'can be deleted' do
        click_on 'Delete Export'
        expect(page).to have_text('Bulk export deleted.')
      end

      it 'can be regenerated' do
        click_on 'Regenerate' do
          expect(page).to have_text('Bulk export regenerating...')
        end
      end
    end

    context 'when viewing their successful bulk export' do
      let!(:user_export) { create(:bulk_export, :queued, created_by: user) }

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

      it 'can be deleted' do
        click_on 'Delete Export'
        expect(page).to have_text('Bulk export deleted.')
      end

      it 'can be regenerated' do
        click_on 'Regenerate' do
          expect(page).to have_text('Bulk export regenerating...')
        end
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

  context 'when filtering Bulk Exports' do
    let(:user) { create(:user, :admin) }
    let(:other_user) { create(:user, :admin) }
    let!(:user_export) { create(:bulk_export, created_by: user) }
    let!(:bulk_export) { create(:bulk_export, created_by: other_user) }

    before do
      sign_in user
      visit bulk_exports_path
    end

    it 'filters by associated user email' do
      select user.email, from: 'Created By'
      click_on 'Submit'
      expect(page).to have_text(user.email, count: 2)
      expect(page).to have_text(other_user.email, count: 1)
    end
  end

  context 'when sorting Bulk Exports' do
    let(:user) { create(:user, :admin) }
    let(:first_export) { create(:bulk_export, :queued, title: 'First') }
    let(:second_export) { create(:bulk_export, :queued, title: 'Second') }

    before do
      persist(:item_resource)
      first_export.process!
      second_export.process!
      sign_in user
      visit bulk_exports_path
    end

    it 'sorts by generated at in ascending order' do
      select 'Generated At', from: 'Sort By'
      select 'Ascending', from: 'Sort Direction'
      click_on 'Submit'
      expect(first('.card')).to have_text(first_export.title)
    end

    it 'sorts by generated at in descending order' do
      select 'Generated At', from: 'Sort By'
      select 'Descending', from: 'Sort Direction'
      click_on 'Submit'
      expect(first('.card')).to have_text(second_export.title)
    end

    it 'sorts by created at in ascending order' do
      select 'Created At', from: 'Sort By'
      select 'Ascending', from: 'Sort Direction'
      click_on 'Submit'
      expect(first('.card')).to have_text(first_export.title)
    end

    it 'sorts by created at in descending order' do
      select 'Created At', from: 'Sort By'
      select 'Descending', from: 'Sort Direction'
      click_on 'Submit'
      expect(first('.card')).to have_text(second_export.title)
    end
  end

  context 'when creating bulk exports' do
    let(:user) { create(:user, :viewer) }

    before do
      sign_in user
      persist(:item_resource)
      visit items_path
    end

    it 'has link to create bulk export' do
      expect(page).to have_text('Export as CSV')
    end

    context 'when redirected to bulk export new form' do
      before do
        fill_in 'Search', with: 'Green'
        click_on 'Submit'
        click_on 'Export as CSV'
      end

      it 'redirects to bulk export new form' do
        expect(page).to have_text('Create Bulk Export')
      end

      it 'fills Search Params field with search params' do
        expect(page).to have_field('bulk-export-search-params', disabled: true)
        field = find_field('bulk-export-search-params', disabled: true)
        expect(field.value).to have_text '"all"=>"Green"'
      end

      it 'creates a bulk export and redirects to bulk export index page' do
        fill_in 'bulk-export-title', with: 'Green'
        click_on 'Create'
        expect(find(class: 'card-title')).to have_text('Green')
      end
    end
  end
end
