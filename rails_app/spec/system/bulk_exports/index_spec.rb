# frozen_string_literal: true

require 'system_helper'

describe 'Bulk Export Index Page' do
  let(:user) { create(:user, role) }

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

      it 'stores per page value across requests' do
        select '25', from: 'Per Page'
        click_button 'Filter'
        click_link 'Items'
        click_link 'Exports'
        expect(page).to have_select('Per Page', selected: '25')
      end
    end

    describe 'viewing a bulk export' do
      context 'when it is queued' do
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
          click_button 'Cancel Export'
          within('div.modal-content') { click_button 'Cancel' }
          expect(page).to have_text('Bulk export cancelled.')
        end
      end

      context 'when it is cancelled' do
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
          click_button 'Delete Export'
          within('div.modal-content') { click_button 'Delete' }
          expect(page).to have_text('Bulk export deleted.')
        end
      end

      context 'when it is processing' do
        let!(:user_export) { create(:bulk_export, :processing, created_by: user) }

        before { visit bulk_exports_path }

        it 'displays the correct state' do
          expect(page).to have_text(user_export.state.titleize)
        end

        it 'does not display any buttons' do
          expect(page).not_to have_button('Export')
        end
      end

      context 'when it is failed' do
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
          click_button 'Delete Export'
          within('div.modal-content') { click_button 'Delete' }
          expect(page).to have_text('Bulk export deleted.')
        end

        it 'can be regenerated' do
          click_button 'Regenerate Export'
          within('div.modal-content') { click_button 'Regenerate' }
          expect(page).to have_text('Bulk export queued for regeneration')
        end
      end

      context 'when it is successful' do
        let!(:user_export) { create(:bulk_export, :queued, created_by: user) }

        before do
          user_export.process!
          visit bulk_exports_path
        end

        it 'displays the correct state' do
          expect(page).to have_text(user_export.state.titleize)
        end

        it 'displays the correct records count' do
          expect(page).to have_text(user_export.records_count)
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
          click_button 'Delete Export'
          within('div.modal-content') { click_button 'Delete' }
          expect(page).to have_text('Bulk export deleted.')
        end

        it 'can be regenerated' do
          click_button 'Regenerate Export'
          within('div.modal-content') { click_button 'Regenerate' }
          expect(page).to have_text('Bulk export queued for regeneration')
        end
      end
    end
  end

  context 'when filtering Bulk Exports' do
    let(:user) { create(:user, :viewer) }
    let(:other_user) { create(:user, :admin) }

    before do
      sign_in user
      create(:bulk_export, created_by: user)
      create(:bulk_export, created_by: other_user)
      visit bulk_exports_path
    end

    it 'filters by associated user email' do
      select user.email, from: 'Created By'
      click_button 'Filter'
      expect(page).to have_text(user.email, count: 2)
      expect(page).to have_text(other_user.email, count: 1)
    end
  end

  context 'when sorting Bulk Exports' do
    let(:user) { create(:user, :viewer) }
    let(:first_export) { create(:bulk_export, :queued, title: 'First') }
    let(:second_export) { create(:bulk_export, :queued, title: 'Second') }

    before do
      persist(:item_resource)
      first_export.process!
      second_export.process!
      sign_in user
      visit bulk_exports_path
    end

    it 'sorts by generated_at in descending order by default' do
      expect(first('.card')).to have_text(second_export.title)
    end

    it 'sorts missing generated_at values first' do
      unprocessed_export = create(:bulk_export, :queued, title: 'unprocessed')
      visit bulk_exports_path
      expect(first('.card')).to have_text(unprocessed_export.title)
    end

    it 'sorts by generated at in ascending order' do
      select 'Generated At', from: 'Sort By'
      select 'Ascending', from: 'Sort Direction'
      click_button 'Filter'
      expect(first('.card')).to have_text(first_export.title)
    end

    it 'sorts by generated at in descending order' do
      select 'Generated At', from: 'Sort By'
      select 'Descending', from: 'Sort Direction'
      click_button 'Filter'
      expect(first('.card')).to have_text(second_export.title)
    end

    it 'sorts by created at in ascending order' do
      select 'Created At', from: 'Sort By'
      select 'Ascending', from: 'Sort Direction'
      click_button 'Filter'
      expect(first('.card')).to have_text(first_export.title)
    end

    it 'sorts by created at in descending order' do
      select 'Created At', from: 'Sort By'
      select 'Descending', from: 'Sort Direction'
      click_button 'Filter'
      expect(first('.card')).to have_text(second_export.title)
    end
  end

  context 'with a logged in viewer' do
    let(:role) { :viewer }

    it_behaves_like 'any logged in user'

    context 'when viewing bulk exports that belong to other users' do
      before do
        sign_in user
        create_list(:bulk_export, 10)
        visit bulk_exports_path
      end

      it 'does not display the buttons' do
        expect(page).not_to have_button('Export')
      end
    end
  end

  context 'with a logged in editor' do
    let(:role) { :editor }

    it_behaves_like 'any logged in user'

    context 'when viewing bulk exports that belong to other users' do
      before do
        sign_in user
        create_list(:bulk_export, 10)
        visit bulk_exports_path
      end

      it 'does not display the buttons' do
        expect(page).not_to have_button('Export')
      end
    end
  end

  context 'with a logged in admin' do
    let(:role) { :admin }

    it_behaves_like 'any logged in user'

    context 'when viewing bulk exports that belong to other users' do
      before do
        sign_in user
        create_list(:bulk_export, 10)
        visit bulk_exports_path
      end

      it 'displays the buttons' do
        expect(page).to have_button('Export')
      end
    end
  end
end
