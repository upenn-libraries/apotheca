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

  describe '#run?' do
    let(:item) { persist(:item_resource) }
    let(:process) { build(:import_process, :update, unique_identifier: item.unique_identifier) }
    let(:result) { process.run }

    it 'fails' do
      expect(result).to be_a Dry::Monads::Failure
    end

    it 'return expected failure object' do
      expect(result.failure[:error]).to be :import_failed
      expect(result.failure[:details]).to contain_exactly('Update process not yet implemented')
    end
  end
end
