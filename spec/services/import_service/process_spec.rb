# frozen_string_literal: true

describe ImportService::Process do
  describe '.build' do

    context 'when action is not a String' do
      let(:process) { build(:import_process, action: []) }

      it 'returns Process::Invalid' do
        expect(process).to be_a ImportService::Process::Invalid
      end
    end

    context 'when action is nil' do
      let(:process) { build(:import_process, action: nil) }

      it 'returns Process::Invalid' do
        expect(process).to be_a ImportService::Process::Invalid
      end
    end

    context 'when action is invalid' do
      let(:process) { build(:import_process, action: 'invalid') }

      it 'returns Process::Invalid' do
        expect(process).to be_a ImportService::Process::Invalid
      end
    end

    context 'when action is create' do
      let(:process) { build(:import_process, :create) }

      it 'returns Process::Create' do
        expect(process).to be_a ImportService::Process::Create
      end
    end

    context 'when action is update' do
      let(:process) { build(:import_process, :update) }

      it 'returns Process::Update' do
        expect(process).to be_a ImportService::Process::Update
      end
    end
  end
end
