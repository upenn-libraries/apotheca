# frozen_string_literal: true

require_relative 'base'

describe ImportService::Process::Update do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :update }
  end

  describe '#valid?' do
    it 'requires a unique_identifier' do
      process = build(:import_process, :update, unique_identifier: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include 'unique_identifier must be provided when updating an Item'
    end

    it 'requires a valid unique_identifier' do
      process = build(:import_process, :update, unique_identifier: 'ark:/99999/fk4invalid')
      expect(process.valid?).to be false
      expect(process.errors).to include 'unique_identifier does not belong to an Item'
    end
  end

  describe '#run' do
    include_context 'with successful requests to update EZID'

    let(:item) { persist(:item_resource, :with_faker_metadata, :with_full_asset) }
    let(:result) { process.run }
    let(:updated_item) { result.value! }

    context 'when updating with missing asset information' do
      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier,
          assets: { storage: 'sceti_digitized', path: 'trade_card/original', arranged_filenames: 'back.tif' }
        )
      end

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'return expected failure object' do
        msg = 'Missing the following assets: front.tif. All assets must be represented when updating assets'
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to contain_exactly(msg)
      end
    end

    context 'when updating item with new assets but files are missing' do
      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier,
          assets: {
            storage: 'sceti_digitized',
            path: 'trade_card/original/front.tif',
            arranged_filenames: 'front.tif;back.tif'
          }
        )
      end

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'return expected failure object' do
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to contain_exactly('Files in storage missing for: back.tif')
      end
    end

    context 'when updating an item\'s descriptive metadata' do
      let(:item) { persist(:item_resource) }
      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier, structural: { viewing_direction: 'left-to-right' },
          metadata: { collection: ['Very important new collection'], physical_format: [{ label: 'New' }], language: [] }
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates expected descriptive metadata' do
        expect(updated_item.descriptive_metadata.collection).to contain_exactly('Very important new collection')
        expect(updated_item.descriptive_metadata.physical_format.pluck(:label)).to contain_exactly('New')
      end

      it 'does not update title' do
        expect(updated_item.descriptive_metadata.title).to match_array(item.descriptive_metadata.title)
      end

      it 'does not update internal notes' do
        expect(updated_item.internal_notes).to match_array(item.internal_notes)
      end

      it 'updates expected structural metadata' do
        expect(updated_item.structural_metadata.viewing_direction).to eql 'left-to-right'
        expect(updated_item.structural_metadata.viewing_hint).to eql item.structural_metadata.viewing_hint
      end

      it 'removes language' do
        expect(updated_item.descriptive_metadata.language).to be_blank
      end
    end

    context 'when adding updating existing assets and adding new assets' do
      let(:updated_assets) do
        Valkyrie::MetadataAdapter.find(:postgres).query_service.find_many_by_ids(ids: updated_item.asset_ids)
      end

      # Only providing the file necessary to test that not all files have to be provided.
      let(:process) do
        build(
          :import_process, :update,
          assets: {
            arranged: [
              { filename: 'front.tif', label: 'Front', transcription: ['Importers'] },
              { filename: 'back.tif',  label: 'Back', annotation: ['mostly blank'] }
            ],
            storage: 'sceti_digitized',
            path: 'trade_card/original/back.tif'
          },
          unique_identifier: item.unique_identifier
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates asset metadata' do
        front = updated_assets.find { |a| a.original_filename == 'front.tif' }
        expect(front.label).to eql 'Front'
        expect(front.transcriptions.map(&:contents)).to contain_exactly('Importers')
      end

      it 'creates new asset' do
        back = updated_assets.find { |a| a.original_filename == 'back.tif' }
        expect(back.label).to eql 'Back'
        expect(back.preservation_file_id).not_to be_nil
      end

      it 'adds new asset to item' do
        expect(updated_item.asset_ids.count).to be 2
      end
    end

    context 'when updating existing assets and there\'s an error' do
      # Triggering an error from the UpdateAsset transaction
      before do
        allow(
          process.asset_set.first
        ).to receive(:update_asset).and_return(Dry::Monads::Failure(error: :invalid_file_extension))
      end

      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier,
          assets: { arranged: [{ filename: 'front.tif', label: 'Front', annotation: ['Business advertisement'] }] }
        )
      end

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'return expected failure object' do
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to contain_exactly(
          'An error was raised while updating one or more assets. All changes were applied except the updates to the asset(s) below. These issues should be fixed manually.',
          'Error occurred updating front.tif - invalid_file_extension'
        )
      end
    end

    context 'when updating existing assets with a new file' do
      let(:updated_assets) do
        updated_item.asset_ids.map do |id|
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: id)
        end
      end

      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier,
          assets: { storage: 'sceti_digitized', path: 'trade_card/updated', arranged_filenames: 'front.tif' }
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates front.tif' do
        front = updated_assets.find { |a| a.original_filename == 'front.tif' }
        expect(
          front.technical_metadata.sha256
        ).to eql 'e8b02e24ff4223af1f4c8a351b7dc8e4b226e4b13c7b3b3e68be827a071e120f'
      end
    end
  end
end
