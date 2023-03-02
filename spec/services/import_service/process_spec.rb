# frozen_string_literal: true

describe ImportService::Process do
  describe '#valid?' do
    it 'requires valid action' do
      process = build(:import_process, action: 'invalid')
      expect(process.valid?).to be false
      expect(process.errors).to include('"invalid" is not a valid import action')
    end

    it 'requires imported_by' do
      process = build(:import_process, imported_by: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include 'imported_by must always be provided'
    end

    context 'when creating a new item' do
      it 'requires metadata' do
        process = build(:import_process, metadata: nil)
        expect(process.valid?).to be false
        expect(process.errors).to include('metadata must be provided to create an object')
      end

      it 'requires assets' do
        process = build(:import_process, assets: nil)
        expect(process.valid?).to be false
        expect(process.errors).to include('assets must be provided to create an object')
      end

      it 'requires human_readable_name' do
        process = build(:import_process, human_readable_name: nil)
        expect(process.valid?).to be false
        expect(process.errors).to include('human_readable_name must be provided to create an object')
      end

      it 'requires all files to be present in storage' do
        process = build(:import_process, assets: { storage: 'sceti_digitized', path: 'trade_card', arranged_filenames: 'new.tif; front.tif' })
        expect(process.valid?).to be false
        expect(process.errors).to include('assets contains the following invalid filenames: new.tif')
      end

      context 'with a unique_identifier already in use' do
        include_context 'with successful requests to lookup EZID'

        let(:process) { build(:import_process, unique_identifier: ark) }
        let(:ark) { persist(:item_resource).unique_identifier }

        it 'adds errors' do
          expect(process.valid?).to be false
          expect(process.errors).to include("\"#{ark}\" already belongs to an object. Cannot create new object with given unique identifier.")
        end
      end

      context 'with an unminted ark' do
        include_context 'with unsuccessful requests to lookup EZID'

        it 'adds error' do
          process = build(:import_process, unique_identifier: 'ark:/99999/fk4invalid')
          expect(process.valid?).to be false
          expect(process.errors).to include('"ark:/99999/fk4invalid" is not minted')
        end
      end
    end

    context 'when updating an item' do
      let(:process) { build(:import_process, :update, unique_identifier: 'ark:/99999/fk4invalid') }

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
  end

  describe '#run' do
    include_context 'with successful requests to mint EZID'
    include_context 'with successful requests to update EZID'

    context 'when creating a new item' do
      let(:process) { build(:import_process) }
      let(:result) { process.run }
      let(:item) { result.value! }

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(item).to be_a ItemResource
      end

      it 'creates expected Item' do
        expect(item.human_readable_name).to eql 'Trade card; J. Rosenblatt & Co.'
        expect(item.descriptive_metadata.collection.first).to eql 'Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'
      end

      it 'has expected number of Assets' do
        expect(item.asset_ids.length).to be 2
        expect(item.structural_metadata.arranged_asset_ids.length).to be 2
      end

      # it 'created expected Assets'
    end
  end
end
