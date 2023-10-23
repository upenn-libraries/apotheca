# frozen_string_literal: true

describe Steps::GenerateIIIFManifest do
  subject(:result) { generate_iiif_manifest_step.call(change_set) }

  let(:generate_iiif_manifest_step) { described_class.new }
  let(:change_set) { ItemChangeSet.new(item) }

  before { freeze_time }
  after  { unfreeze_time }

  describe '#call' do
    context 'when item resource contains image assets' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'adds derivative resource' do
        expect(result.value!.derivatives.count).to be 1
        expect(result.value!.derivatives.first).to have_attributes(
          file_id: an_instance_of(Valkyrie::ID),
          type: 'iiif_manifest',
          mime_type: 'application/json',
          generated_at: DateTime.current
        )
      end

      it 'creates iiif manifest and stores it' do
        expect(result.value!.derivatives.count).to be 1
        expect(
          Valkyrie::StorageAdapter.find_by(id: result.value!.derivatives.first.file_id)
        ).to be_a Valkyrie::StorageAdapter::File
      end
    end

    context 'when item resource contains non-image assets' do
      let(:asset) { persist(:asset_resource, technical_metadata: { mime_type: 'audio/wav' }) }
      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'does not add a derivative resource' do
        expect(result.value!.derivatives.count).to be 0
      end
    end
  end
end
