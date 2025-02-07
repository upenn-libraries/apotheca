# frozen_string_literal: true

describe GenerateAllDerivativesJob do
  let(:job) { described_class.new }

  describe '#transaction' do
    include_context 'with successful publish request'

    let(:item) { persist(:item_resource, :with_full_assets_all_arranged, :published) }
    let(:result) { job.transaction(item.id.to_s, Settings.system_user) }

    let(:generate_derivatives) { GenerateDerivatives.new }
    let(:publish_item) { PublishItem.new }

    before do
      allow(GenerateDerivatives).to receive(:new).and_return(generate_derivatives)
      allow(generate_derivatives).to receive(:call).with(any_args).and_call_original

      allow(PublishItem).to receive(:new).and_return(publish_item)
      allow(publish_item).to receive(:call).with(any_args).and_call_original
    end

    it 'regenerates asset derivatives' do
      result
      item.asset_ids.each do |asset_id|
        expect(generate_derivatives).to have_received(:call).with(id: asset_id.to_s, updated_by: Settings.system_user)
      end
    end

    it 'publishes item' do
      result
      expect(publish_item).to have_received(:call).with(id: item.id.to_s, updated_by: Settings.system_user)
    end

    context 'when error regenerating asset derivatives' do
      before do
        allow(GenerateDerivatives).to receive(:new).and_return(generate_derivatives)
        allow(generate_derivatives).to receive(:call).with(any_args) do
          Dry::Monads::Failure.new(error: :error_generating_derivatives)
        end
      end

      it 'return failure' do
        expect(result).to be_a Dry::Monads::Failure
        expect(result.failure[:error]).to be :error_generating_derivatives
      end
    end

    context 'when item is not published' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged, published: false) }

      before do
        allow(PublishItem).to receive(:new).and_return(publish_item)
        allow(publish_item).to receive(:call).with(any_args).and_call_original
      end

      it 'does not publish item' do
        result
        expect(publish_item).not_to have_received(:call).with(id: item.id.to_s, updated_by: Settings.system_user)
      end
    end

    context 'when error publishing item' do
      before do
        allow(PublishItem).to receive(:new).and_return(publish_item)
        allow(publish_item).to receive(:call).with(any_args) { Dry::Monads::Failure.new(error: :error_publishing_item) }
      end

      it 'return failure' do
        expect(result).to be_a Dry::Monads::Failure
        expect(result.failure[:error]).to be :error_publishing_item
      end
    end
  end
end
