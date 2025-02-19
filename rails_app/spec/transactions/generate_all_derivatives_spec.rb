# frozen_string_literal: true

describe GenerateAllDerivatives do
  describe '#call' do
    let(:transaction) { described_class.new }
    let(:item) { persist(:item_resource, :with_full_assets_all_arranged, :published) }
    let(:result) { transaction.call(id: item.id, updated_by: Settings.system_user) }

    let(:generate_derivatives) { GenerateDerivatives.new }

    before do
      allow(GenerateDerivatives).to receive(:new).and_return(generate_derivatives)
      allow(generate_derivatives).to receive(:call).with(any_args).and_call_original
    end

    context 'when item published' do
      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'regenerates asset derivatives' do
        result
        item.asset_ids.each do |asset_id|
          expect(generate_derivatives).to have_received(:call).with(id: asset_id.to_s, updated_by: Settings.system_user)
        end
      end

      it 'enqueues publish job' do
        result
        expect(PublishItemJob).to have_enqueued_sidekiq_job(item.id.to_s, Settings.system_user)
      end
    end

    context 'when item is not published' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged, published: false) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'does not enqueue publish job' do
        result
        expect(PublishItemJob).not_to have_enqueued_sidekiq_job(any_args)
      end
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

    context 'when republish is false' do
      let(:result) { transaction.call(id: item.id, updated_by: Settings.system_user, republish: false) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'does not enqueue publish job' do
        result
        expect(PublishItemJob).not_to have_enqueued_sidekiq_job(any_args)
      end
    end
  end
end
