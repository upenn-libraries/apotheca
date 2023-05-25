# frozen_string_literal: true

require_relative 'base'

describe ImportService::Process::Create do
  it_behaves_like 'a ImportService::Process::Base' do
    let(:import_action) { :create }
  end

  describe '#valid?' do
    it 'requires metadata' do
      process = build(:import_process, :create, metadata: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include('metadata must be provided to create an object')
    end

    it 'requires assets' do
      process = build(:import_process, :create, assets: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include('assets must be provided to create an object')
    end

    it 'requires human_readable_name' do
      process = build(:import_process, :create, human_readable_name: nil)
      expect(process.valid?).to be false
      expect(process.errors).to include('human_readable_name must be provided to create an object')
    end

    it 'requires all files to be present in storage' do
      assets = { storage: 'sceti_digitized', path: 'trade_card/original', arranged_filenames: 'new.tif; front.tif' }
      process = build(:import_process, :create, assets: assets)
      expect(process.valid?).to be false
      expect(process.errors).to include('assets contains the following invalid filenames: new.tif')
    end

    context 'with a unique_identifier already in use' do
      include_context 'with successful requests to lookup EZID'

      let(:process) { build(:import_process, :create, unique_identifier: ark) }
      let(:ark) { persist(:item_resource).unique_identifier }

      it 'adds errors' do
        expect(process.valid?).to be false
        expect(process.errors).to include("\"#{ark}\" already assigned to an item")
      end
    end

    context 'with an unminted ark' do
      include_context 'with unsuccessful requests to lookup EZID'

      it 'adds error' do
        process = build(:import_process, :create, unique_identifier: 'ark:/99999/fk4invalid')
        expect(process.valid?).to be false
        expect(process.errors).to include('"ark:/99999/fk4invalid" is not minted')
      end
    end
  end

  describe '#run' do
    include_context 'with successful requests to mint EZID'
    include_context 'with successful requests to update EZID'

    let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres).query_service }

    let(:result) { process.run }
    let(:item) { result.value! }
    let(:assets) { item.structural_metadata.arranged_asset_ids.map { |id| query_service.find_by(id: id) } }

    context 'when creating a new item' do
      let(:process) { build(:import_process, :create) }

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(item).to be_a ItemResource
      end

      it 'creates expected Item' do
        expect(item.human_readable_name).to eql 'Trade card; J. Rosenblatt & Co.'
        expect(
          item.descriptive_metadata.collection.first
        ).to eql 'Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'
      end

      it 'has expected number of Assets' do
        expect(item.asset_ids.length).to be 2
        expect(item.structural_metadata.arranged_asset_ids.length).to be 2
      end

      it 'created expected Assets' do
        expect(assets[0].original_filename).to eql 'front.tif'
        expect(assets[1].original_filename).to eql 'back.tif'
      end
    end

    context 'when creating a new item with asset metadata' do
      let(:process) { build(:import_process, :create, :with_asset_metadata) }

      it 'is successful' do
        expect(result).to be_a Dry::Monads::Success
        expect(item).to be_a ItemResource
      end

      it 'creates asset with expected transcription' do
        expect(assets[0].label).to eql 'Front'
        expect(assets[0].transcriptions[0].contents).to eql 'Importers'
      end

      it 'creates asset with expected annotation' do
        expect(assets[1].label).to eql 'Back'
        expect(assets[1].annotations[0].text).to eql 'mostly blank'
      end

      it 'generates derivatives' do
        expect(assets[0].derivatives.length).to be 2
        expect(assets[1].derivatives.length).to be 2
      end
    end

    context 'when creating an item with a metadata error' do
      let(:process) { build(:import_process, :create, metadata: { subjects: ['Trade Cards'] }) }

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'returns expected failure object' do
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to contain_exactly('Validation failed: Title can\'t be blank')
      end

      it 'does not leave orphaned assets or items' do
        expect(query_service.find_all.count).to be 0
      end
    end

    context 'when creating and item with an asset error' do
      # Mock a miscellaneous error arising from file characterization.
      before do
        fits = instance_double(FileCharacterization::Fits)
        allow(FileCharacterization::Fits).to receive(:new) { fits }
        allow(fits).to receive(:examine).and_raise(
          FileCharacterization::Fits::Error,
          'Could not successfully characterize contents: Unexpected Error'
        )
      end

      let(:process) { build(:import_process, :create) }

      it 'fails' do
        expect(result).to be_a Dry::Monads::Failure
      end

      it 'return expected failure object' do
        expect(result.failure[:error]).to be :import_failed
        expect(result.failure[:details]).to contain_exactly(
          'Error raised when generating front.tif',
          'File characterization failed: Could not successfully characterize contents: Unexpected Error'
        )
      end
    end
  end
end
