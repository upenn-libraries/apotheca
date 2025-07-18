# frozen_string_literal: true

describe MigrateAccessToIIIFImageDerivativeJob do


  let(:job) { described_class.new }

  describe '#perform' do
    let(:asset) { persist(:asset_resource, :with_image_file) }
    let(:item) do
      persist(:item_resource, :published, asset_ids: [asset.id], thumbnail_asset_id: [asset.id],
              structural_metadata: { arranged_asset_ids: [asset.id] })
    end
    let(:add_iiif_image_transaction) { AddIIIFImageDerivative.new }
    let(:iiif_manifest_transaction) { GenerateIIIFManifests.new }

    before do
      allow(GenerateIIIFManifests).to receive(:new).and_return(iiif_manifest_transaction)
      allow(iiif_manifest_transaction).to receive(:call).and_call_original
      allow(AddIIIFImageDerivative).to receive(:new).and_return(add_iiif_image_transaction)
      allow(add_iiif_image_transaction).to receive(:call).and_call_original
    end

    context 'when item id is invalid' do
      it 'raises an error' do
        expect { job.perform('invalid') }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when item does not contain image assets' do
      let(:asset) { persist(:asset_resource, :with_video_file) }

      it 'does not run AddIIIFImageDerivative' do
        job.perform(item.id.to_s)
        expect(add_iiif_image_transaction).not_to have_received(:call)
      end

      it 'does not run GenerateIIIFManifests' do
        job.perform(item.id.to_s)
        expect(iiif_manifest_transaction).not_to have_received(:call)
      end
    end

    context 'when item contains assets with iiif_image derivatives' do
      let(:asset) { persist(:asset_resource, :with_image_file, :with_derivatives) }

      it 'does not run AddIIIFImageDerivative' do
        job.perform(item.id.to_s)
        expect(add_iiif_image_transaction).not_to have_received(:call)
      end

      it 'runs GenerateIIIFManifests' do
        job.perform(item.id.to_s)
        expect(iiif_manifest_transaction).to have_received(:call)
      end
    end

    context 'when there is an error generating a iiif_image derivative' do
      include_context 'with access derivative'

      before do
        allow(add_iiif_image_transaction).to receive(:call).and_return(
          Dry::Monads::Failure.new(:iiif_image_derivative_already_present)
        )
      end

      it 'raises an error' do
        expect { job.perform(item.id.to_s) }.to raise_error("Error migrating to iiif_image derivative for #{asset.id}")
      end
    end

    context 'when there is an error generating the iiif manifest' do
      include_context 'with access derivative'

      before do
        allow(iiif_manifest_transaction).to receive(:call).and_return(
          Dry::Monads::Failure.new(:error_generating_iiif_manifest)
        )
      end

      it 'raises an error' do
        expect { job.perform(item.id.to_s) }.to raise_error('Error regenerating IIIF manifest')
      end
    end

    context 'when item is not published' do
      include_context 'with access derivative'

      let(:item) do
        persist(:item_resource, asset_ids: [asset.id], thumbnail_asset_id: [asset.id],
                structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      it 'does not call GenerateIIIFManifests' do
        job.perform(item.id.to_s)
        expect(iiif_manifest_transaction).not_to have_received(:call).with(id: item.id.to_s, updated_by: Settings.system_user)
      end
    end

    context 'when item has image assets' do
      include_context 'with access derivative'

      it 'calls AddIIIFImageDerivative transaction for each asset' do
        job.perform(item.id.to_s)
        expect(add_iiif_image_transaction).to have_received(:call).with(id: asset.id.to_s, updated_by: Settings.system_user)
      end

      it 'calls GenerateIIIFManifests' do
        job.perform(item.id.to_s)
        expect(iiif_manifest_transaction).to have_received(:call).with(id: item.id.to_s, updated_by: Settings.system_user)
      end

      it 'deletes access derivative files' do
        shrine = Valkyrie::StorageAdapter.find(:iiif_derivatives).shrine
        expect(shrine.exists?("#{asset.id}/access")).to be true
        job.perform(item.id.to_s)
        expect(shrine.exists?("#{asset.id}/access")).to be false
      end
    end
  end
end
