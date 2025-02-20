# frozen_string_literal: true

require_relative 'base'

describe ImportService::Process::Update do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :update }
  end

  describe '#valid?' do
    let(:item) { persist(:item_resource) }

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

    it 'requires provided item thumbnail to exist when assets are present' do
      process = build(:import_process, :update, :with_asset_metadata,
                      thumbnail: 'test.tif')
      expect(process.valid?).to be false
      expect(process.errors).to include 'provided thumbnail does not exist in provided assets'
    end

    it 'requires provided item thumbnail to exist when assets are not present' do
      process = build(:import_process, :update, thumbnail: 'test.tif', unique_identifier: item.unique_identifier)
      expect(process.valid?).to be false
      expect(process.errors).to include 'provided thumbnail does not exist in existing assets'
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
        msg = ['All assets must be represented when updating assets; the following assets are missing:', "\tfront.tif"]
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to match_array(msg)
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
      let(:process) do
        build(
          :import_process, :update,
          unique_identifier: item.unique_identifier,
          structural: { viewing_direction: 'left-to-right' },
          metadata: {
            collection: [{ value: 'Very important new collection' }],
            physical_format: [{ value: 'New' }],
            language: []
          }
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates expected descriptive metadata' do
        expect(
          updated_item.descriptive_metadata.collection.pluck(:value)
        ).to contain_exactly('Very important new collection')
        expect(updated_item.descriptive_metadata.physical_format.pluck(:value)).to contain_exactly('New')
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

      it 'does not publish item' do
        expect(updated_item).to have_attributes(published: false, last_published_at: nil, first_published_at: nil)
      end

      it 'does not regenerates all asset derivatives' do
        generate_all_derivatives = GenerateAllDerivatives.new
        allow(GenerateAllDerivatives).to receive(:new).and_return(generate_all_derivatives)
        allow(generate_all_derivatives).to receive(:call).with(any_args).and_call_original
        result
        expect(generate_all_derivatives).not_to have_received(:call).with(id: updated_item.id.to_s,
                                                                          updated_by: 'importer@example.com')
      end
    end

    context 'when updating multiple existing assets' do
      let(:item) do
        persist(:item_resource, :with_faker_metadata, :with_assets_all_arranged,
                asset1: persist(:asset_resource, :with_preservation_file, original_filename: 'page1'),
                asset2: persist(:asset_resource, :with_preservation_file, original_filename: 'page2'))
      end

      let(:updated_assets) do
        Valkyrie::MetadataAdapter.find(:postgres).query_service.find_many_by_ids(ids: updated_item.asset_ids)
      end

      let(:process) do
        build(
          :import_process, :update,
          assets: {
            arranged: [
              { filename: 'page1', label: 'recto' },
              { filename: 'page2', label: 'verso', annotation: ['test'] }
            ]
          },
          unique_identifier: item.unique_identifier
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates the metadata for multiple assets' do
        first_asset = updated_assets.find { |a| a.original_filename == 'page1' }
        second_asset = updated_assets.find { |a| a.original_filename == 'page2' }

        expect(first_asset.label).to eql 'recto'
        expect(second_asset.annotations.map(&:text)).to contain_exactly('test')
      end
    end

    context 'when updating existing assets and adding new assets' do
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
          'All changes were applied except the updates to the asset(s) below. These issues must be fixed manually:',
          "\tError occurred updating front.tif: Invalid file extension"
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

    context 'when updating the thumbnail' do
      let(:item) { persist(:item_resource, :with_assets_all_arranged) }
      let(:process) do
        build(:import_process, :update, unique_identifier: item.unique_identifier, thumbnail: 'page2')
      end
      let(:updated_assets) do
        updated_item.asset_ids.map do |id|
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: id)
        end
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates the thumbnail' do
        expect(updated_item.thumbnail_asset_id).to eq item.structural_metadata.arranged_asset_ids.last
      end
    end

    context 'when updating an item with additional asset and there\'s an error' do
      # Returning a virus check failure when updating the newly created asset.
      before do
        step_double = instance_double(Steps::VirusCheck)
        allow(Steps::VirusCheck).to receive(:new).and_return(step_double)
        allow(step_double).to receive(:call).with(hash_including(file: a_value)) do
          Dry::Monads::Failure.new(error: :virus_detected)
        end
      end

      let(:process) do
        build(
          :import_process, :update,
          assets: {
            arranged: [
              { filename: 'front.tif' },
              { filename: 'back.tif', label: 'Back', annotation: ['mostly blank'] }
            ],
            storage: 'sceti_digitized',
            path: 'trade_card/original/back.tif'
          },
          unique_identifier: item.unique_identifier
        )
      end

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'removes newly created asset' do
        result
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: AssetResource).count
        ).to be 1
      end

      it 'does not record any events' do
        result
        expect(ResourceEvent.count).to be 0
      end
    end

    context 'when updating and publishing an item' do
      include_context 'with successful publish request'

      let(:process) do
        build(
          :import_process, :update, :publish,
          unique_identifier: item.unique_identifier,
          metadata: { collection: [{ value: 'Very important new collection' }] }
        )
      end

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(updated_item).to be_a ItemResource
      end

      it 'updates metadata' do
        expect(
          updated_item.descriptive_metadata.collection.pluck(:value)
        ).to contain_exactly('Very important new collection')
      end

      it 'publishes item' do
        expect(updated_item).to have_attributes(
          published: true, first_published_at: be_a(DateTime), last_published_at: be_a(DateTime)
        )
      end
    end

    context 'when ocr_type is blank' do
      let(:item) { persist(:item_resource, :with_faker_metadata) }
      let(:updated_assets) do
        updated_item.asset_ids.map do |id|
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: id)
        end
      end

      let(:process) do
        build(:import_process, :update, unique_identifier: item.unique_identifier, ocr_type: nil,
                                        assets: { arranged_filenames: 'front.tif', storage: 'sceti_digitized',
                                                  path: 'trade_card/original' })
      end

      it 'does not generate OCR derivatives' do
        expect(updated_assets.first.derivatives.map(&:type)).to contain_exactly('access', 'thumbnail')
      end
    end

    context 'when adding new assets without providing language metadata' do
      let(:item) { persist(:item_resource, :with_faker_metadata) }
      let(:updated_assets) do
        updated_item.asset_ids.map do |id|
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: id)
        end
      end

      let(:process) do
        build(
          :import_process, :update, :printed,
          assets: { arranged_filenames: 'front.tif', storage: 'sceti_digitized', path: 'trade_card/original' },
          unique_identifier: item.unique_identifier
        )
      end

      it 'generates ocr derivatives using existing item metadata' do
        expect(updated_assets.first.derivatives.map(&:type)).to include('textonly_pdf', 'hocr', 'text')
      end
    end

    context 'when updating language property and existing preservation file' do
      let(:item) { persist(:item_resource, :with_full_asset) }

      let(:updated_assets) do
        updated_item.asset_ids.map do |id|
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_by(id: id)
        end
      end

      let(:process) do
        build(
          :import_process, :update, :printed,
          metadata: { language: [{ value: 'English' }] },
          assets: { arranged_filenames: 'front.tif', storage: 'sceti_digitized', path: 'trade_card/updated' },
          unique_identifier: item.unique_identifier
        )
      end

      it 'sets ocr_type' do
        expect(updated_item).to have_attributes(ocr_type: 'printed')
      end

      it 'generates ocr derivatives' do
        expect(updated_assets.first.derivatives.map(&:type)).to include('textonly_pdf', 'hocr', 'text')
      end

      it 'regenerates all asset derivatives' do
        generate_all_derivatives = GenerateAllDerivatives.new
        allow(GenerateAllDerivatives).to receive(:new).and_return(generate_all_derivatives)
        allow(generate_all_derivatives).to receive(:call).with(any_args).and_call_original
        result
        expect(generate_all_derivatives).to have_received(:call).with(id: updated_item.id.to_s,
                                                                      updated_by: 'importer@example.com',
                                                                      republish: false)
      end
    end
  end

  describe '#regenerate_asset_derivatives?' do
    subject(:regenerate_asset_derivatives) { process.send(:regenerate_asset_derivatives?) }

    let(:process) do
      build(:import_process, :update, unique_identifier: item.unique_identifier)
    end

    context 'when ocr_type is nil' do
      let(:item) { persist(:item_resource, :with_faker_metadata, :with_full_asset) }

      context 'when ocr_type not updated' do
        it { is_expected.to be false }
      end

      context 'when ocr_type updated' do
        let(:process) do
          build(:import_process, :update, :printed, unique_identifier: item.unique_identifier)
        end

        it { is_expected.to be true }
      end
    end

    context 'when ocr_type is printed' do
      let(:item) { persist(:item_resource, :with_faker_metadata, :with_full_asset, :printed) }

      it 'when language nor viewing direction are changed' do
        expect(regenerate_asset_derivatives).to be false
      end

      context 'when language is changed' do
        let(:process) do
          build(:import_process, :update, unique_identifier: item.unique_identifier,
                                          metadata: { language: [{ value: 'French' }] })
        end

        it { is_expected.to be true }
      end

      context 'when viewing_direction is changed' do
        let(:process) do
          build(:import_process, :update, unique_identifier: item.unique_identifier,
                                          structural: { viewing_direction: 'left-to-right' })
        end

        it { is_expected.to be true }
      end
    end
  end
end
